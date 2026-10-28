import Cocoa
import TGUIKit
import SwiftSignalKit
import InAppSettings
import Localization
import InputDataUI
import GeneralRows
import TelegramContext
import TelegramTheme
import ColorPalette
import FoundationUtils

enum ModSettingsText {
    case title
    case recommendedChannelsTitle
    case recommendedChannelsInfo
    case storiesTitle
    case storiesInfo

    private var isRussian: Bool {
        return appCurrentLanguage.languageCode.hasPrefix("ru")
    }

    var value: String {
        switch self {
        case .title:
            return isRussian ? "Настройка мода" : "Mod Settings"
        case .recommendedChannelsTitle:
            return isRussian ? "Отключить рекомендованные каналы" : "Disable Recommended Channels"
        case .recommendedChannelsInfo:
            return isRussian
                ? "Скрывает блок с рекомендованными каналами в чатах, поиске и профилях."
                : "Hides recommended channels in chats, search and profiles."
        case .storiesTitle:
            return isRussian ? "Отключить все истории" : "Disable All Stories"
        case .storiesInfo:
            return isRussian
                ? "Скрывает истории и кольца историй в списке чатов, профилях, поиске и сообщениях."
                : "Hides stories and story rings in the chat list, profiles, search and messages."
        }
    }
}

private final class Arguments {
    let toggleRecommendedChannels: () -> Void
    let toggleStories: () -> Void

    init(toggleRecommendedChannels: @escaping () -> Void, toggleStories: @escaping () -> Void) {
        self.toggleRecommendedChannels = toggleRecommendedChannels
        self.toggleStories = toggleStories
    }
}

private struct State: Equatable {
    var hideRecommendedChannels: Bool
    var hideAllStories: Bool
}

private let _id_recommended_channels = InputDataIdentifier("_id_recommended_channels")
private let _id_stories = InputDataIdentifier("_id_stories")

private func entries(_ state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries: [InputDataEntry] = []

    var sectionId: Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(ModSettingsText.recommendedChannelsTitle.value), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_recommended_channels, data: .init(name: ModSettingsText.recommendedChannelsTitle.value, color: theme.colors.text, type: .switchable(state.hideRecommendedChannels), viewType: .singleItem, action: arguments.toggleRecommendedChannels)))
    index += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(ModSettingsText.recommendedChannelsInfo.value), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem)))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(ModSettingsText.storiesTitle.value), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_stories, data: .init(name: ModSettingsText.storiesTitle.value, color: theme.colors.text, type: .switchable(state.hideAllStories), viewType: .singleItem, action: arguments.toggleStories)))
    index += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(ModSettingsText.storiesInfo.value), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem)))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    return entries
}

public func ModSettingsController(context: any AccountContextProtocol) -> InputDataController {
    let initialState = State(hideRecommendedChannels: FastSettings.hideRecommendedChannels, hideAllStories: FastSettings.hideAllStories)

    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)

    let updateState: ((State) -> State) -> Void = { f in
        statePromise.set(stateValue.modify(f))
    }

    let arguments = Arguments(toggleRecommendedChannels: {
        updateState { current in
            var current = current
            current.hideRecommendedChannels = !current.hideRecommendedChannels
            FastSettings.hideRecommendedChannels = current.hideRecommendedChannels
            return current
        }
    }, toggleStories: {
        updateState { current in
            var current = current
            current.hideAllStories = !current.hideAllStories
            FastSettings.hideAllStories = current.hideAllStories
            return current
        }
    })

    let signal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
        return InputDataSignalValue(entries: entries(state, arguments: arguments))
    }

    let controller = InputDataController(dataSignal: signal, title: ModSettingsText.title.value, hasDone: false)
    return controller
}
