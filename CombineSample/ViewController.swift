//
//  ViewController.swift
//  CombineSample
//
//  Created by akifumi.fukaya on 2019/06/13.
//  Copyright © 2019 Akifumi Fukaya. All rights reserved.
//

import UIKit
import Combine

final class ViewModel {
    struct StatusText {
        let content: String
        let color: UIColor
    }
    @Published
    var status: StatusText = StatusText(content: "NG", color: .red)

    @Published
    var username: String? = nil
    private var validatedUsername: AnyPublisher<String?, Never> {
        return $username
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { (username) -> AnyPublisher<String?, Never> in
                Future<String?, Never> { (promise) in
                    // FIXME: API request
                    guard let username = username else {
                        promise(.success(nil))
                        return
                    }
                    if 1...10 ~= username.count {
                        promise(.success(username))
                    } else {
                        promise(.success(nil))
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private var cancellables: [AnyCancellable] = []

    init() {
        // Update StatusText
        let usernameCancellable = validatedUsername
            .map { (value) -> StatusText in
                if let _ = value {
                    return StatusText(content: "OK", color: .green)
                } else {
                    return StatusText(content: "NG", color: .red)
                }
            }
            .sink { [weak self] (value) in
                self?.status = value
            }

        cancellables = [usernameCancellable]
    }

    func viewDidLoad(username: String?) {
        // error: Segmentation fault: 11. This may be a bug.
        // self.username = username
    }

    func viewDidDisappear() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }
}

class ViewController: UIViewController {
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var textField: UITextField!

    private let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        viewModel.viewDidLoad(username: textField.text)

        // First value
        viewModel.username = textField.text
    }

    private func bind() {
        _ = viewModel.$username
            .subscribe(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                print("validatedUsername.receiveCompletion: \(completion)")
            }, receiveValue: { [weak self] (value) in
                print("validatedUsername.receiveValue: \(value ?? "nil")")
                self?.textField.text = value
            })
        _ = viewModel.$status
            .subscribe(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                print("viewModel.statusSubject.receiveCompletion: \(completion)")
            }, receiveValue: { [weak self] (value) in
                print("viewModel.statusSubject.receiveValue: \(value)")
                guard let self = self else { return }
                self.statusLabel.text = value.content
                self.statusLabel.textColor = value.color
            })
    }
}

extension ViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text
            .flatMap({ $0 as NSString })?
            .replacingCharacters(in: range, with: string)
        viewModel.username = text

        return false
    }
}
