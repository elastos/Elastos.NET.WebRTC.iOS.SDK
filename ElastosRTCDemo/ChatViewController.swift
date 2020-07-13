//
//  ChatViewController.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/7/13.
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

    var messages: [MockMessage] = []

    init(sender: MockUser) {
        self.sender = sender
        super.init(nibName: nil, bundle: nil)

        self.messages = [.init(text: "111", user: sender, messageId: "111", date: Date()),
                         .init(text: "222", user: sender, messageId: "111", date: Date())]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMessageInputBar()
        configureMessageCollectionView()
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
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "Aa"
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }

    private func insertMessages(_ data: [Any]) {
        for component in data {
            let user = self.sender
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            } else if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            }
        }
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate { }

extension UIColor {
    static let primaryColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
}
