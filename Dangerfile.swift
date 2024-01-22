import Danger
import Foundation

let danger = Danger()

// MARK: - Helpers

extension NSRegularExpression {
    func hasMatch(in text: String) -> Bool {
        matchesGroups(in: text).first?.isEmpty == false
    }

    func firstMatch(in text: String) -> Substring? {
        matchesGroups(in: text).first?.first
    }

    func matchesGroups(in text: String) -> [[Substring]] {
        matches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        )
        .map { match in
            (0..<match.numberOfRanges).compactMap {
                let rangeBounds = match.range(at: $0)
                guard let range = Range(rangeBounds, in: text) else {
                    return nil
                }
                return text[range]
            }
        }
    }
}

func catchError<T>(_ block: () throws -> T) -> T {
    do {
        return try block()
    } catch {
        danger.fail("Во время выполнения получили исключение: \(error)")
        exit(1)
    }
}

enum DangerKeys {
    static let releaseBranchKey = "DANGER_RELEASE_BRANCH_PATTERN"
}

// MARK: - PR check

final class PRNamingChecker {
    enum Constants {
        static let projectList = [
            "ADD", "TUTUID", "AVIA", "BUS", "VID", "ECO", "RAIL", "MAPP", "HOTELS", "ETRAIN", "MCORE", "COMP", "DS"
        ]
        static let numberlessProjectList = ["NO-ISSUE"]
        static let notReleaseBranchPrefixes = ["feature", "bugfix", "hotfix", "utility", "tests", "ci"]
    }

    private let _danger: DangerDSL
    private let _releaseBranchPattern: String
    private let _projectRegexPattern: String

    private lazy var _errorHintProjects = (
        Constants.projectList.map { "\($0)-{номер задачи}" } + Constants.numberlessProjectList
    ).joined(separator: " или ")

    init(danger: DangerDSL, releasePattern: String) {
        _danger = danger
        _releaseBranchPattern = releasePattern

        _projectRegexPattern = {
            var projectsRegex = Constants.projectList.map { #"\#($0)-\d+"# }
            projectsRegex.append(contentsOf: Constants.numberlessProjectList)
            return projectsRegex.joined(separator: "|")
        }()
    }

    func validatePR(branchName: String, prTitle: String) {
        if _isReleaseBranch(branchName) {
            _ensureReleasePRTitleValid(prTitle)
        } else if _isFeatureOrTestBranch(branchName) {
            _ensureFeaturePRTitleValid(branchName: branchName, prTitle: prTitle)
        } else {
            let notReleaseBranches = Constants.notReleaseBranchPrefixes.joined(separator: " или ")
            _danger.fail("""
                Если ветка начинается на \(notReleaseBranches), то далее должно быть \(_errorHintProjects).
                Релизная ветка должна удовлетворять паттерну \(_releaseBranchPattern) и содержать номер версии
            """)
        }
    }

    private func _isReleaseBranch(_ branch: String) -> Bool {
        let regex = catchError { try NSRegularExpression(pattern: #"^\#(_releaseBranchPattern)[0-9\.]+$"#) }
        return regex.hasMatch(in: branch)
    }

    private func _isFeatureOrTestBranch(_ branch: String) -> Bool {
        let prefixes = Constants.notReleaseBranchPrefixes.joined(separator: "|")
        let pattern = #"^(\#(prefixes))\/(\#(_projectRegexPattern))(-|_)[a-zA-Z0-9_-]+$"#
        let regex = catchError { try NSRegularExpression(pattern: pattern) }
        return regex.hasMatch(in: branch)
    }

    private func _ensureReleasePRTitleValid(_ title: String) {
        let regex = catchError { try NSRegularExpression(pattern: "^NO-ISSUE: [Rr]elease") }
        if !regex.hasMatch(in: title) {
            _danger.fail("Заголовок релиза должен начинаться на NO-ISSUE: Release или NO-ISSUE: release")
        }
    }

    private func _ensureFeaturePRTitleValid(branchName: String, prTitle: String) {
        let nameRegex = catchError { try NSRegularExpression(pattern: _projectRegexPattern) }

        guard let branchNameMatch = nameRegex.firstMatch(in: branchName) else {
            _danger.fail(
                "Название PR должно начинаться с \(_errorHintProjects) и должно совпадать с таким-же названием ветки"
            )
            return
        }
        guard let prNameMatches = nameRegex.firstMatch(in: prTitle) else {
            _danger.fail("Название PR должно начинаться с \(_errorHintProjects)")
            return
        }
        if branchNameMatch.lowercased() != prNameMatches.lowercased() {
            _danger.fail("Идентификатор задачи в ветке и в названии PR должны совпадать")
        }
    }
}

// MARK: - PR Size

final class PRSizeChecker {
    enum Constants {
        static let warningSize = 500
        static let errorSize = 750
    }

    private let _danger: DangerDSL

    init(danger: DangerDSL) {
        _danger = danger
    }

    func validatePRSize() {
        guard let addedLinesCount = danger.github.pullRequest.additions else {
            _danger.warn("Не удалось получить количество измененных строк из PR")
            return
        }

        let sourceBranch = _danger.github.pullRequest.base.ref
        _danger.message("Source branch = \(sourceBranch)")
        let changedPbxproj = _getUpdatedLinesCount(in: .pbxproj, sourceBranch: sourceBranch)
        let changedSnapshots = _getSnapshotChangedCount()
        let codeInserts = addedLinesCount - changedPbxproj - changedSnapshots

        _danger.message("""
        Размер PR:
        \(codeInserts) строк кода добавлено/обновлено;
        \(changedPbxproj) строк в файлах .pbxproj добавлено/обновлено;
        \(changedSnapshots) snapshot тестов добавлено/обновлено;
        Всего: \(addedLinesCount)
        """)
        if codeInserts > Constants.errorSize {
            fail("Размер PR (\(codeInserts) строк кода) превышает максимальный размер (\(Constants.errorSize) строк).")
        } else if addedLinesCount > Constants.warningSize {
            warn("Размер PR (\(codeInserts) строк кода) превышает рекомендуемый размер (\(Constants.warningSize) строк).")
        }
    }

    private func _getUpdatedLinesCount(in fileType: FileType, sourceBranch: String) -> Int {
        return (_danger.git.modifiedFiles + _danger.git.createdFiles)
            .filter { $0.fileType == fileType }
            .compactMap { file in
                do {
                    return try _danger.utils.diff(forFile: file, sourceBranch: sourceBranch).get()
                } catch {
                    _danger.warn("Не удалось получить diff для файла \(file). Ошибка: \(error)")
                    return nil
                }
            }
            .reduce(0) { partialResult, file in
                switch file.changes {
                case let .created(lines):
                    return partialResult + lines.count
                case let .modified(hunks):
                    let added = hunks
                        .reduce(0) {
                            $0 + $1.lines.filter { line in line.description.hasPrefix("+") }.count
                        }
                    return partialResult + added
                default:
                    return partialResult
                }
            }
    }

    private func _getSnapshotChangedCount() -> Int {
        (_danger.git.modifiedFiles + _danger.git.createdFiles)
            .filter { $0.contains("/__Snapshots__/") }
            .count
    }
}

// MARK: - Main
guard let releasePatternValue = danger.utils.environment.releaseBranchPattern else {
    danger.fail("""
    Параметр "\(DangerKeys.releaseBranchKey)" обязателен.
    env:
        \(DangerKeys.releaseBranchKey): "release/(transport|avia|train|bus)-"
    """
    )
    exit(1)
}
guard case let .string(releasePattern) = releasePatternValue else {
    danger.fail(#"Параметр "\#(DangerKeys.releaseBranchKey)" должен быть строкой"#)
    exit(1)
}

let prNameChecker = PRNamingChecker(danger: danger, releasePattern: releasePattern)
prNameChecker.validatePR(branchName: danger.github.pullRequest.head.ref, prTitle: danger.github.pullRequest.title)

danger.message("PWD = \(try! danger.utils.spawn("pwd"))")
danger.message("LS = \(try! danger.utils.spawn("ls -a"))")

let prSizeChecker = PRSizeChecker(danger: danger)
prSizeChecker.validatePRSize()

if danger.github.pullRequest.body?.isEmpty == true {
    danger.warn("Отсутствует описание PR")
}
