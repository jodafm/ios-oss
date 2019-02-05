import KsApi
import Library
import Prelude
import UIKit

internal final class PaymentMethodsViewController: UIViewController, MessageBannerViewControllerPresenting {
  private let dataSource = PaymentMethodsDataSource()
  private let viewModel: PaymentMethodsViewModelType = PaymentMethodsViewModel()

  @IBOutlet private weak var tableView: UITableView!

  internal var messageBannerViewController: MessageBannerViewController?

  public static func instantiate() -> PaymentMethodsViewController {
    return Storyboard.Settings.instantiate(PaymentMethodsViewController.self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.messageBannerViewController = self.configureMessageBannerViewController(on: self)

    self.tableView.dataSource = self.dataSource
    self.tableView.delegate = self
    self.tableView.register(nib: .CreditCardCell)
    self.tableView.registerHeaderFooter(nib: .PaymentMethodsFooterView)
    self.tableView.registerHeaderFooter(nib: .SettingsTableViewHeader)

    self.configureHeaderFooterViews()

    self.viewModel.inputs.viewDidLoad()
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: Strings.discovery_favorite_categories_buttons_edit(),
      style: .plain,
      target: self,
      action: #selector(edit)
    )

    self.viewModel.inputs.viewDidLoad()

    self.dataSource.deletionHandler = { [weak self] creditCard in
      self?.viewModel.inputs.didDelete(creditCard)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.viewModel.inputs.viewWillAppear()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    guard let footerView = tableView.tableFooterView, let headerView = tableView.tableHeaderView else {
      return
    }

    footerView.setNeedsLayout()
    footerView.layoutIfNeeded()

    headerView.setNeedsLayout()
    headerView.layoutIfNeeded()

    let footerViewHeight = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    var frame = footerView.frame
    frame.size.height = footerViewHeight
    footerView.frame = frame

    let headerViewHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    var headerFrame = headerView.frame
    headerFrame.size.height = headerViewHeight
    headerView.frame = headerFrame

    tableView.tableFooterView = footerView
    tableView.tableHeaderView = headerView
  }

  override func bindStyles() {
    super.bindStyles()

    _ = self
      |> settingsViewControllerStyle
      |> UIViewController.lens.title %~ { _ in
        Strings.Payment_methods()
    }

    _ = self.tableView
      |> \.backgroundColor .~ .clear
      |> \.rowHeight .~ Styles.grid(11)
      |> \.allowsSelection .~ false
      |> \.separatorStyle .~ .none
  }

  override func bindViewModel() {
    super.bindViewModel()

    self.viewModel.outputs.paymentMethods
      .observeForUI()
      .observeValues { [weak self] result in
        self?.dataSource.load(creditCards: result)
        self?.tableView.reloadData()
    }

    self.viewModel.outputs.reloadData
      .observeForUI()
      .observeValues { [weak self] in
        self?.tableView.reloadData()
    }

    self.viewModel.outputs.goToAddCardScreen
      .observeForUI()
      .observeValues { [weak self] in
        self?.goToAddCardScreen()
    }

    self.viewModel.outputs.presentBanner
      .observeForUI()
      .observeValues { [weak self] message in
        self?.messageBannerViewController?.showBanner(with: .success, message: message)
    }

    self.viewModel.outputs.tableViewIsEditing
      .observeForUI()
      .observeValues { [weak self] isEditing in
        self?.tableView.setEditing(isEditing, animated: true)
    }

    self.viewModel.outputs.showAlert
      .observeForControllerAction()
      .observeValues { [weak self] message in
        self?.present(UIAlertController.genericError(message), animated: true)
    }
  }

  // MARK: - Actions

  @objc private func edit() {
    self.viewModel.inputs.editButtonTapped()
  }

  private func goToAddCardScreen() {
    let vc = AddNewCardViewController.instantiate()
    vc.delegate = self
    let nav = UINavigationController(rootViewController: vc)
    nav.modalPresentationStyle = .formSheet

    self.present(nav, animated: true, completion: nil)
  }

  // MARK: - Private Helpers
  private func configureHeaderFooterViews() {
    let footerView = tableView.dequeueReusableHeaderFooterView(
  withIdentifier: Nib.PaymentMethodsFooterView.rawValue
      ) as? PaymentMethodsFooterView
    footerView?.delegate = self

    let headerView = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: Nib.SettingsTableViewHeader.rawValue) as? SettingsTableViewHeader
    headerView?.configure(with: Strings.Any_payment_methods_you_saved_to_Kickstarter())

    self.tableView.tableFooterView = footerView
    self.tableView.tableHeaderView = headerView
  }
}

extension PaymentMethodsViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0.1
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.1
  }
}

extension PaymentMethodsViewController: PaymentMethodsFooterViewDelegate {
  internal func paymentMethodsFooterViewDidTapAddNewCardButton(_ footerView: PaymentMethodsFooterView) {
    self.viewModel.inputs.paymentMethodsFooterViewDidTapAddNewCardButton()
  }
}

extension PaymentMethodsViewController: AddNewCardViewControllerDelegate {
  internal func presentAddCardSuccessfulBanner(_ message: String) {
    self.viewModel.inputs.cardAddedSuccessfully(message)
  }
}
