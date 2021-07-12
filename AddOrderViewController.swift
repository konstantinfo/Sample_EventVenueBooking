//
//  AddOrderViewController.swift
//
//  Created by ios on 28/09/20.
//  Copyright © 2020 com. All rights reserved.
//

import UIKit

class AddOrderViewController: UIViewController {
    @IBOutlet weak var totalBillView: TotalBillView!
    @IBOutlet weak var paymentView: PaymentView!
    @IBOutlet weak var addProductButton: UIButton!
    @IBOutlet weak var detailView: DetailCellView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var orderEntryView: OrderEntryView!
    @IBOutlet weak var createOrderButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    // MARK: - Variables
    private var orderViewModel = AddOrderViewModel()
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        startActivity()
    }
    private func startActivity() {
        setUI()
        setData()
        callDeliveryApi()
    }
    private func setUI() {
        self.addBackButton()
        self.totalBillView.isHidden = true
        addProductButton.isHidden = true
        addProductButton.borderColor = Color.lightPurple.value
        addProductButton.setTitleColor(Color.lightPurple.value, for: .normal)
        addProductButton.titleLabel?.font = Font(.installed(.RedHatDisplayMedium), size: .standard(.h24)).instance
        addProductButton.setTitle(VendorConstant.add_more_product.value, for: .normal)
        createOrderButton.setButtonPrimaryDesign()
        self.containerView.backgroundColor = Color.background.value
        detailView.setSelectProductUI()
    }
    private func setData() {
        createOrderButton.setTitle(orderViewModel.buttonText, for: .normal)
        navigationItem.title = VendorConstant.addOrder.value
        self.orderViewModel.paymentType = .no
        paymentView.onButtonAction = { action in
            self.orderViewModel.paymentType = action
        }
        detailView.onButtonAction = { [weak self] in
            self?.moveToProudctList()
        }

    }
    fileprivate func moveToProudctList() {
        do {
            let validation = Validation()
            let dictValues = self.orderEntryView.getValues()
            try validation.validateAreaAndCity(dictValues)
            if let charges = dictValues?[.charges] as? String, let index = Int(charges) {
                self.gotoProductSelection(index: index)
            }
        } catch {
            self.showErroMessage(message: VendorConstant.manadaryAreaCity.value)
        }
    }
    private func gotoProductSelection(index: Int) {
        let dictValues = orderEntryView.getValues()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateFormatterTime = DateFormatter()
        dateFormatterTime.dateFormat = "HH:mm"

        let date = dateFormatter.string(from: self.orderEntryView.dateTextField.textfield.date!)
        let time = dateFormatterTime.string(from: self.orderEntryView.dateTextField.textfield.date!)
        UserDefaultsManager.shared.OrderSelectedDate = date
        UserDefaultsManager.shared.OrderSelectedTime = time
        UserDefaultsManager.shared.OrderSelectedAreaID = dictValues?[OrderEntryView.Field.area]!! ?? ""
        let charges = orderViewModel.getCharges(index)
        self.gotoSelectProductPage( charges, { product, validation in
            self.orderViewModel.selectedProduct = product
            if self.orderViewModel.selectedProducts == nil {
                self.orderViewModel.selectedProducts = [FestProduct]()
            }
            if let selectedProduct = product {
                self.addProductButton.isHidden = false
                self.detailView.isHidden = true
                self.totalBillView.isHidden = false
                self.totalBillView.configureAddProductsTotal()
                self.orderViewModel.selectedProducts?.append(selectedProduct)
            }
            let total = self.orderViewModel.addMultProduct(validation)
            let totalWithCurrency = "\(total ?? 0.0)" + VendorConstant.kd.value.addSpaceAtBeginning()
            self.totalBillView.updateTotalBill(totalWithCurrency, subTotal: nil)
            self.detailView.setProductData(product)
        }, products: self.orderViewModel.selectedProducts)

    }
    private func updateCity() {
        self.orderEntryView.setViewModel(orderViewModel)
    }

    private func showErrow(_ validateError: ValidationError) {
        var targetView: UIView?
        switch validateError {
        case .emptyCity:
            targetView = orderEntryView.cityTextField
            orderEntryView.cityTextField.errorMessage = validateError.value
        case .emptyDate:
            targetView = orderEntryView.dateTextField
            orderEntryView.dateTextField.errorMessage = validateError.value
        case .emptyName:
            targetView = orderEntryView.nameTextField
            orderEntryView.nameTextField.errorMessage = validateError.value
        case .emptyArea:
            targetView = orderEntryView.areaTextField
            orderEntryView.areaTextField.errorMessage = validateError.value
        case .emptyStreet:
            targetView = orderEntryView.streetTextField
            orderEntryView.streetTextField.errorMessage = validateError.value
        case .emptyAvenue:
            targetView = orderEntryView.avenueTextField
            orderEntryView.avenueTextField.errorMessage = validateError.value
        case .emptyBuildingNum:
            targetView = orderEntryView.buildingNumTextField
            orderEntryView.buildingNumTextField.errorMessage = validateError.value
        case .emptyBlock:
            targetView = orderEntryView.blockTextField
            orderEntryView.blockTextField.errorMessage = validateError.value
        case .emptyEmail, .invalidEmail :
            targetView = orderEntryView.emailTextField
            orderEntryView.emailTextField.errorMessage = validateError.value
        case .emptyMobile, .invalidMobile:
            targetView = orderEntryView.mobileTextField
            orderEntryView.mobileTextField.errorMessage = validateError.value
        case .emptyPayment, .emptyProduct:
            self.showErroMessage(message: validateError.value)
        default: return
        }
        if let center = targetView?.frame {
            self.scrollView.setContentOffset(CGPoint(x: center.minX, y: center.minY), animated: true)
        }
    }
    fileprivate func validateFields(_ dictValues: [OrderEntryView.Field: String?]?) {
        let validation = Validation()
        do {
            try validation.validateField(dictValues)
            self.callOrder(productValidate: orderViewModel.productValidation, customeValidation: validation)
        } catch {
            if let validateError = error as? ValidationError {
                self.showErrow(validateError)
            }
        }
    }
    @IBAction func addProductButtonAction(_ sender: UIButton) {
        self.moveToProudctList()
    }
    @IBAction func createOrderButtonAction(_ sender: UIButton) {

        var dictValues = orderEntryView.getValues()
        dictValues?[OrderEntryView.Field.payment] = orderViewModel.paymentType?.value
        dictValues?[OrderEntryView.Field.productId] = orderViewModel.getAllProductIds()
        validateFields(dictValues)
    }
}
// MARK: - Api Call
extension AddOrderViewController {
    private func callDeliveryApi() {
        if !Reachability.isConnectedToNetwork() {
            self.showInternetPage()
            return
        }
        DeliveryApiManager().callDeliveryChargeApi(self) { data in
            if let festCities = data {
                self.orderViewModel.festCities = festCities
                self.updateCity()
            }
        }
    }
    private func callOrder(productValidate: Validation?, customeValidation: Validation?) {
        if !Reachability.isConnectedToNetwork() {
            self.showInternetPage()
            return
        }
        ProductApiManager(productValidation: productValidate,
                          customerInfoValidation: customeValidation).callSaveOrderApi(self) { _ in
                            self.backAction()
        }
    }
}
