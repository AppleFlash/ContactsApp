import Danger
import Foundation

let danger = Danger()

// MARK: - Helpers

// NOTE: Временное решение.
// Из-за сложностей применение команд `git ...` на облачных раннерах GitHub CI не удаётся использовать
// встроенные в danger-swift функции получения диффа. Решение взято отсюда
// https://github.com/tutu-ru-mobile/TutuGraphTool/blob/main/Sources/SharedComponents/Tools/GitDiffParser.swift
// После переезда на собственную ферму подход будет пересмотрен
struct FileDiff: Hashable {
    let oldPath: String?
    let newPath: String?
    let diffType: FileDiffType
    let addedLines: [String]
    let deletedLines: [String]

    enum FileDiffType: String {
        case created
        case changed
        case deleted
    }
}

extension FileDiff: CustomDebugStringConvertible {
    var debugDescription: String {
        return """
        oldPath: \(oldPath?.debugDescription ?? "nil"),
        newPath: \(newPath?.debugDescription ?? "nil"),
        diffType: \(diffType),
        addedLinesCount: \(addedLines.count),
        deletedLinesCount: \(deletedLines.count),
        """
    }
}

enum GitDiffParser {
    enum Errors: Error, CustomStringConvertible {
        case unexpectedBehaviour(String? = nil)

        var description: String {
            let commonMessage = "Looks like either an error exists in parsing algorithm or parsed diff is invalid."
            switch self {
            case let .unexpectedBehaviour(description):
                return description.map { commonMessage + " " + $0 } ?? commonMessage
            }
        }
    }

    static func parse(_ diff: String) throws -> [FileDiff] {
        let lines = diff.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        let diffChangedFilePathRegex = try NSRegularExpression(
            pattern: #"^diff --git (a\/.+) (b\/.+)$"#
        )

        let binaryFilesDifferPathsRegex = try NSRegularExpression(
            pattern: #"^Binary files (.+) and (.+) differ$"#
        )

        var oldPath: String?
        var newPath: String?
        var addedLines: [String] = []
        var deletedLines: [String] = []

        var results: [FileDiff] = []

        func parsePath<T: StringProtocol>(from string: T) -> String? {
            if string == "/dev/null" { return nil }
            return String(string.dropFirst(2))
        }

        func cleanModifiedLine(_ line: String.SubSequence) -> String {
            guard line.first == "+" || line.first == "-" else { return String(line) }
            return line.dropFirst(1).trimmingCharacters(in: .whitespaces)
        }

        func finishDiffHunkParsing() {
            if oldPath != nil || newPath != nil {
                let diffType: FileDiff.FileDiffType
                if oldPath == nil {
                    diffType = .created
                } else if newPath == nil {
                    diffType = .deleted
                } else {
                    diffType = .changed
                }

                results.append(
                    FileDiff(
                        oldPath: oldPath,
                        newPath: newPath,
                        diffType: diffType,
                        addedLines: addedLines,
                        deletedLines: deletedLines
                    )
                )
            }

            oldPath = nil
            newPath = nil
            addedLines = []
            deletedLines = []
        }

        for line in lines {
            let firstWord = line.split(separator: " ", omittingEmptySubsequences: false).first

            switch firstWord {
            case "diff":
                finishDiffHunkParsing()
                if let groups = diffChangedFilePathRegex.firstMatchGroups(in: String(line)) {
                    oldPath = parsePath(from: groups[1])
                    newPath = parsePath(from: groups[2])
                }

            case "---":
                oldPath = parsePath(from: line.dropFirst(4))

            case "+++":
                newPath = parsePath(from: line.dropFirst(4))

            case "\\":
                if line == "\\ No newline at end of file" {
                } else {
                    throw Errors.unexpectedBehaviour("unexpected diff line: \(String(line))")
                }

            case "Binary":
                if let groups = binaryFilesDifferPathsRegex.firstMatchGroups(in: String(line)) {
                    oldPath = parsePath(from: groups[1])
                    newPath = parsePath(from: groups[2])
                } else {
                    throw Errors.unexpectedBehaviour("unexpected diff line: \(String(line))")
                }

            default:
                switch line.first {
                case "+":
                    addedLines.append(cleanModifiedLine(line))
                case "-":
                    deletedLines.append(cleanModifiedLine(line))
                default:
                    break
                }
            }
        }

        finishDiffHunkParsing()

        return results
    }
}

extension NSRegularExpression {
    func hasMatch(in text: String) -> Bool {
        matchesGroups(in: text).first?.isEmpty == false
    }

    func firstMatch(in text: String) -> Substring? {
        matchesGroups(in: text).first?.first
    }

    func firstMatchGroups(in text: String) -> [Substring]? {
        matchesGroups(in: text).first
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
    private let _diffContent: String
    private lazy var _parsedDiffFiles = catchError { try GitDiffParser.parse(_diffContent) }

    init(danger: DangerDSL, diffContent: String) {
        _danger = danger
        _diffContent = diffContent
    }

    func validatePRSize() {
        guard let addedLinesCount = danger.github.pullRequest.additions else {
            _danger.warn("Не удалось получить количество измененных строк из PR")
            return
        }

        let changedPbxproj = _getUpdatedLinesCount(in: .pbxproj)
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

    private func _getUpdatedLinesCount(in fileType: FileType) -> Int {
        _parsedDiffFiles
            .lazy
            .filter { $0.diffType == .changed || $0.diffType == .created }
            .filter { ($0.newPath ?? $0.oldPath)?.fileType == fileType }
            .reduce(0) { partialResult, fileDiff in
                return partialResult + fileDiff.addedLines.count
            }
    }

    private func _getSnapshotChangedCount() -> Int {
        (_danger.git.modifiedFiles + _danger.git.createdFiles)
            .filter { $0.contains("/__Snapshots__/") }
            .count
    }
}

// MARK: - Check naming
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
prNameChecker.validatePR(branchName: "feature/NO-ISSUE_new_font_update", prTitle: "NO-ISSUE. Bump TutuDesignKit to add new fonts.")

// MARK: - Check PR size
//if case let .string(diffFileName) = danger.utils.environment.diffFile {
//    let content = danger.utils.readFile(diffFileName)
//    let prSizeChecker = PRSizeChecker(danger: danger, diffContent: content)
//    prSizeChecker.validatePRSize()
//} else {
//    danger.warn("Размер PR не может быть определен. Файл с diff контентом не установлен")
//}
//
//// MARK: - Check PR description
//if danger.github.pullRequest.body?.isEmpty == true {
//    danger.warn("Отсутствует описание PR")
//}
