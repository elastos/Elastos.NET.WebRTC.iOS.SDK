//
//  ChatViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/7/13.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import MessageKit
import InputBarAccessoryView

struct ImageMediaItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}

struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
}

struct MockMessage: MessageType {

	var messageId: String
	var sender: SenderType {
	    return user
	}
	var sentDate: Date
	var kind: MessageKind

	var user: MockUser

	private init(kind: MessageKind, user: MockUser, messageId: String, date: Date) {
	    self.kind = kind
	    self.user = user
	    self.messageId = messageId
	    self.sentDate = date
	}

	init(text: String, user: MockUser, messageId: String, date: Date) {
	    self.init(kind: .text(text), user: user, messageId: messageId, date: date)
	}

	init(image: UIImage, user: MockUser, messageId: String, date: Date) {
	    let mediaItem = ImageMediaItem(image: image)
	    self.init(kind: .photo(mediaItem), user: user, messageId: messageId, date: date)
	}
}

class ChatViewController: MessagesViewController, MessagesDataSource {

    let sender: MockUser
    let other: MockUser
    let client: WebRtcClient
    var messages: [MockMessage] = []
    var callState: MediaCallState {
        didSet {
            self.title = callState.state
        }
    }

    init(sender: String, to: String ,client: WebRtcClient, state: MediaCallState) {
        self.sender = MockUser(senderId: sender, displayName: sender)
        self.other = MockUser(senderId: to, displayName: sender)
        self.client = client
        self.callState = state
        super.init(nibName: nil, bundle: nil)
        
        self.messages = DataManager.shared.read(from: to)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMessageInputBar()
        configureMessageCollectionView()
        setupObserver()
        self.title = callState.state
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "结束", style: .done, target: self, action: #selector(endChat))
    }
    
    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(_:)), name: .iceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reject(_:)), name: .reject, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected(_:)), name: .iceDisconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMessageFromDataChannel(_:)), name: .receiveMessage, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.messagesCollectionView.reloadData()
    }

    func currentSender() -> SenderType {
        sender
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }

    //TODO: 检查消息是否属于当前的会话？丢弃如果不属于当前会话
    @objc func didReceiveMessageFromDataChannel(_ notification: Notification) {
        if let userInfo = notification.userInfo, let data = userInfo["data"] as? Data,
            let isBinary = userInfo["isBinary"] as? Bool {
            if isBinary, let img = UIImage(data: data) {
                let message = MockMessage(image: img, user: other, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            } else if let str = String(data: data, encoding: .utf8) {
                let message = MockMessage(text: str, user: other, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            }
        }
    }
}

extension ChatViewController {

    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(UIColor.primaryColor.withAlphaComponent(0.3), for: .highlighted)
    }

    func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false

        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        layout?.setMessageOutgoingCellBottomLabelAlignment(.init(textAlignment: .right, textInsets: .zero))
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))

        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        additionalBottomInset = 30
    }

    func insertMessage(_ message: MockMessage) {
        messages.append(message)
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messages.count - 1])
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }

    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."

        for component in components {
            if let str = component as? String, let data = str.data(using: .utf8) {
                let result = try? self.client.sendData(data, isBinary: false)
                print("[SEND]: " + "<" + str + "> " + (result == true ? "data-channel sent success" : "data-channel sent failure"))
            } else if let img = component as? UIImage, let data = img.pngData() {
                let result = try? self.client.sendData(data, isBinary: true)
                print("[SEND]: <image>" + (result == true ? "data-channel sent success" : "data-channel sent failure"))
            }
        }
        DispatchQueue.main.async {
            self.messageInputBar.sendButton.stopAnimating()
            self.messageInputBar.inputTextView.placeholder = "Aa"
            self.insertMessages(components)
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }

    private func insertMessages(_ data: [Any]) {
        for component in data {
            let user = self.sender
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
                DataManager.shared.write(message: str, from: sender.senderId, to: other.senderId)
            } else if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            }
        }
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate { }

extension ChatViewController {

    @objc func connected(_ notification: NSNotification) {
        self.callState = .connected
    }

    @objc func disconnected(_ notification: NSNotification) {
        self.callState = .hangup
        alert(title: "聊天室挂断") { _ in
             DispatchQueue.main.async {
                 self.dismiss(animated: true, completion: nil)
             }
         }
    }

    @objc func reject(_ notification: NSNotification) {
        self.callState = .reject
        alert(title: "对方拒绝加入聊天室") { _ in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc func endChat() {
        alert(title: "结束会话？") { _ in
            self.client.endCall()
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension UIColor {
    static let primaryColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
}
