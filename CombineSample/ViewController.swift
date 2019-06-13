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
    let statusSubject = CurrentValueSubject<StatusText, Never>(StatusText(content: "NG", color: .red))

    let usernameSubject = CurrentValueSubject<String?, Never>(nil)
    private var validatedUsername: AnyPublisher<String?, Never> {
        return usernameSubject
//            .debounce(for: 0.5, scheduler: RunLoop.main)
//            .removeDuplicates()
            .flatMap { (username) -> AnyPublisher<String?, Never> in
                Publishers.Future<String?, Never> { (promise) in
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

    func viewDidLoad() {
        // Update StatusText
        _ = validatedUsername
            .map { (value) -> StatusText in
                if let _ = value {
                    return StatusText(content: "OK", color: .green)
                } else {
                    return StatusText(content: "NG", color: .red)
                }
            }
            .sink { [weak self] (value) in
                self?.statusSubject.send(value)
            }
    }
}

class ViewController: UIViewController {
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

