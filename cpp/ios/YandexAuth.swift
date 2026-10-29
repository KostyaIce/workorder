import AuthenticationServices
import UIKit
import YandexLoginSDK

/// Native Yandex Login SDK wrapper for the Qt app.
///
/// Uses the SDK's web authorization through ASWebAuthenticationSession and the
/// app's `yx<clientId>` URL scheme, so no loopback HTTP server is involved.
@objc(WorkOrderYandexAuth)
public final class WorkOrderYandexAuth: NSObject {
    private static let instance = WorkOrderYandexAuth()

    @objc public class func shared() -> WorkOrderYandexAuth {
        instance
    }

    private var completion: ((String?, String?) -> Void)?
    private var activatedClientId: String?

    private override init() {
        super.init()
        YandexLoginSDK.shared.add(observer: self)
    }

    @objc public func authorize(clientId: String, completion: @escaping (String?, String?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.completion == nil else {
                completion(nil, "Вход уже выполняется")
                return
            }
            do {
                if self.activatedClientId != clientId {
                    try YandexLoginSDK.shared.activate(
                        with: clientId,
                        authorizationStrategy: .webOnly
                    )
                    self.activatedClientId = clientId
                }
                guard let controller = Self.topViewController() else {
                    completion(nil, "Не удалось открыть окно входа Яндекс")
                    return
                }
                self.completion = completion
                try YandexLoginSDK.shared.authorize(
                    with: controller,
                    customValues: nil,
                    authorizationStrategy: .webOnly,
                    webAuthorizationMethod: .system
                )
            } catch {
                self.completion = nil
                completion(nil, Self.describe(error))
            }
        }
    }

    @objc public func cancel() {
        completion = nil
    }

    @objc public func logout() {
        try? YandexLoginSDK.shared.logout()
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
            ?? windowScene?.windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }

    private static func describe(_ error: Error) -> String {
        if let sessionError = error as? ASWebAuthenticationSessionError,
           sessionError.code == .canceledLogin {
            return "Вход отменён"
        }
        if let sdkError = error as? YandexLoginSDKError {
            return sdkError.message
        }
        return error.localizedDescription
    }
}

extension WorkOrderYandexAuth: YandexLoginSDKObserver {
    public func didFinishLogin(with result: Result<LoginResult, Error>) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let completion = self.completion else { return }
            self.completion = nil
            switch result {
            case .success(let loginResult):
                completion(loginResult.token, nil)
            case .failure(let error):
                completion(nil, Self.describe(error))
            }
        }
    }
}
