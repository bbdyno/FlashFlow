//
//  GlassCardView.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class GlassCardView: UIView {
    enum Face {
        case front
        case back
    }

    private let glassContainer = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let highlightView = UIView()
    private let iconImageView = UIImageView()
    private let stateBadgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let detailLabel = UILabel()
    private let helperLabel = UILabel()

    private let highlightGradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureStyle()
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        highlightGradient.frame = highlightView.bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 24).cgPath
    }

    func configure(with studyCard: StudyCard) {
        let card = studyCard.content
        let title = CardTextSanitizer.normalizeMultiline(card.title)
        titleLabel.text = title

        let deckTitle = CardTextSanitizer.normalizeSingleLine(studyCard.deckTitle)
        let note = CardTextSanitizer.normalizeSingleLine(card.subtitle)
        let subtitle: String
        if note.isEmpty || CardTextSanitizer.isLegacyNoNote(note) {
            subtitle = deckTitle
        } else {
            subtitle = "\(deckTitle) · \(note)"
        }
        subtitleLabel.text = subtitle

        let detail = CardTextSanitizer.normalizeMultiline(card.detail)
        detailLabel.text = detail

        titleLabel.font = titleFont(for: title)
        subtitleLabel.font = subtitleFont(for: subtitle)
        detailLabel.font = detailFont(for: detail)
        stateBadgeLabel.text = badgeText(for: studyCard.schedule.state)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        iconImageView.image = UIImage(systemName: card.imageName, withConfiguration: symbolConfig)
        setFace(.front, animated: false)
    }

    func setFace(_ face: Face, animated: Bool) {
        let applyState = {
            switch face {
            case .front:
                self.detailLabel.isHidden = true
                self.helperLabel.isHidden = false
            case .back:
                self.detailLabel.isHidden = false
                self.helperLabel.isHidden = true
            }
        }

        if animated {
            UIView.transition(
                with: glassContainer,
                duration: 0.24,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                applyState()
            }
        } else {
            applyState()
        }
    }

    func applyDragTranslation(_ translation: CGPoint, in bounds: CGRect) {
        let normalizedX = max(min(translation.x / bounds.width, 1.0), -1.0)
        let normalizedY = max(min(translation.y / bounds.height, 1.0), -1.0)

        var transform3D = CATransform3DIdentity
        transform3D.m34 = -1.0 / 650.0
        transform3D = CATransform3DRotate(transform3D, normalizedX * 0.35, 0, 1, 0)
        transform3D = CATransform3DRotate(transform3D, -normalizedY * 0.22, 1, 0, 0)

        layer.transform = transform3D
        transform = CGAffineTransform(translationX: translation.x, y: translation.y * 0.30)
    }

    func resetTransformWithSpring(velocity: CGPoint, completion: (() -> Void)? = nil) {
        let normalizedVelocity = min(max(abs(velocity.x) / 1_200.0, 0.15), 2.0)

        UIView.animate(
            withDuration: 0.72,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: normalizedVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) { [weak self] in
            guard let self else { return }
            self.transform = .identity
            self.layer.transform = CATransform3DIdentity
        } completion: { _ in
            completion?()
        }
    }

    private func configureHierarchy() {
        addSubview(glassContainer)
        glassContainer.addSubview(blurView)
        glassContainer.addSubview(highlightView)
        glassContainer.addSubview(iconImageView)
        glassContainer.addSubview(stateBadgeLabel)
        glassContainer.addSubview(titleLabel)
        glassContainer.addSubview(subtitleLabel)
        glassContainer.addSubview(detailLabel)
        glassContainer.addSubview(helperLabel)
    }

    private func configureStyle() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 30
        layer.shadowOffset = CGSize(width: 0, height: 16)

        glassContainer.layer.cornerRadius = 24
        glassContainer.layer.cornerCurve = .continuous
        glassContainer.layer.borderWidth = 1
        glassContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        glassContainer.clipsToBounds = true

        blurView.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.03)

        highlightGradient.colors = [
            UIColor.white.withAlphaComponent(0.34).cgColor,
            UIColor.white.withAlphaComponent(0.10).cgColor,
            UIColor.clear.cgColor
        ]
        highlightGradient.locations = [0.0, 0.38, 1.0]
        highlightGradient.startPoint = CGPoint(x: 0, y: 0)
        highlightGradient.endPoint = CGPoint(x: 1, y: 1)
        highlightView.layer.addSublayer(highlightGradient)
        highlightView.isUserInteractionEnabled = false

        iconImageView.tintColor = UIColor.white.withAlphaComponent(0.88)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        iconImageView.layer.cornerRadius = 16
        iconImageView.layer.cornerCurve = .continuous

        stateBadgeLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
        stateBadgeLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        stateBadgeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        stateBadgeLabel.layer.cornerRadius = 12
        stateBadgeLabel.layer.cornerCurve = .continuous
        stateBadgeLabel.layer.borderWidth = 1
        stateBadgeLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        stateBadgeLabel.clipsToBounds = true
        stateBadgeLabel.textAlignment = .center

        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30) ?? .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping

        subtitleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping

        detailLabel.font = UIFont(name: "AvenirNext-Medium", size: 17) ?? .systemFont(ofSize: 17, weight: .medium)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping

        helperLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        helperLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        helperLabel.textAlignment = .left
        helperLabel.numberOfLines = 0
        helperLabel.text = "Tap card to reveal answer"
    }

    private func configureLayout() {
        glassContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        highlightView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(24)
            make.size.equalTo(56)
        }

        stateBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.trailing.equalToSuperview().inset(24)
            make.width.greaterThanOrEqualTo(96)
            make.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(28)
        }

        helperLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(28)
        }
    }

    private func badgeText(for state: CardState) -> String {
        switch state {
        case .new:
            return "NEW"
        case .learning:
            return "LEARNING"
        case .review:
            return "REVIEW"
        case .relearning:
            return "RELEARNING"
        }
    }

    private func lineCount(in text: String) -> Int {
        let count = text
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .count
        return max(1, count)
    }

    private func titleFont(for text: String) -> UIFont {
        let length = text.count
        let lines = lineCount(in: text)
        let size: CGFloat

        if lines >= 4 || length >= 120 {
            size = 24
        } else if lines >= 3 || length >= 80 {
            size = 26
        } else if lines >= 2 || length >= 50 {
            size = 28
        } else {
            size = 30
        }

        return UIFont(name: "AvenirNext-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }

    private func subtitleFont(for text: String) -> UIFont {
        let length = text.count
        let size: CGFloat = length >= 55 ? 14 : 15
        return UIFont(name: "AvenirNext-DemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }

    private func detailFont(for text: String) -> UIFont {
        let length = text.count
        let lines = lineCount(in: text)
        let size: CGFloat

        if lines >= 7 || length >= 260 {
            size = 14.5
        } else if lines >= 5 || length >= 180 {
            size = 15.5
        } else if lines >= 3 || length >= 120 {
            size = 16
        } else {
            size = 17
        }

        return UIFont(name: "AvenirNext-Medium", size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }
}
