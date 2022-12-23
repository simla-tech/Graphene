//
//  VariableEncoderContainer.swift
//  Graphene
//
//  Created by Ilya Kharlamov on 28.01.2021.
//

import Foundation

private enum ApplyChangeSetResult {
    case value(Variable?)
    case none
}

public class VariableEncoderContainer {

    private var encoder: VariableEncoder

    internal init(_ encoder: VariableEncoder) {
        self.encoder = encoder
    }

    private func applyChangeSet(
        to value: Variable?,
        forKey key: String,
        changeSet: AnyChangeSet?,
        required: Bool
    ) -> ApplyChangeSetResult {

        guard let changeSet else {
            return .value(value)
        }

        guard let change = changeSet.first(where: key) else {
            return required ? .value(value) : .none
        }

        switch change {
        case let rootChange as RootChange:
            let childChangeSet = AnyChangeSet(changes: rootChange.childChanges)

            if let value = value as? EncodableVariable {
                let diffVariable = ChangeSetVariable(variable: value, changeSet: childChangeSet)
                return .value(diffVariable)

            } else if let values = (value as Any) as? [AnyChangeSetIdentifiableVariable] {

                let variables = values.compactMap({ value -> Variable? in
                    switch self.applyChangeSet(
                        to: value,
                        forKey: "\(value.anyChangeSetIdentifier)",
                        changeSet: childChangeSet,
                        required: false
                    ) {
                    case .value(let variable): return variable
                    default: return nil
                    }
                })
                return .value(ArrayOfVariables(variables: variables))

            } else {
                return .value(value)
            }

        case let fieldChange as FieldChange:
            return .value(fieldChange.newValue)

        default:
            return required ? .value(value) : .none
        }

    }

    public func encode(_ value: Variable?, forKey key: String, required: Bool = false) {
        switch self.applyChangeSet(to: value, forKey: key, changeSet: self.encoder.changeSet, required: required) {
        case .value(let newValue):
            self.encoder.variables.updateValue(newValue, forKey: key)
        default:
            break
        }
    }

    public func encodeIfPresent(_ value: Variable?, forKey key: String, required: Bool = false) {
        guard let value else { return }
        self.encode(value, forKey: key, required: required)
    }

}

private struct ArrayOfVariables: Variable {
    var variables: [Variable]
    var json: Any? { self.variables.map(\.json) }
}
