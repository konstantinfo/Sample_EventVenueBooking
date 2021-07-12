//
//  AddOrderViewModel.swift
//
//  Created by ios on 28/09/20.
//  Copyright © 2020 com. All rights reserved.
//

import UIKit
protocol OrderField {
    var city: String? { get set }
    var date: String? { get set }
    // MARK: - Methods
    func setFieldData()

}
class AddOrderViewModel: NSObject {
    let buttonText = VendorConstant.creatOfflineOrder.value
    var festCities: FestCity?
    var selectedProduct: FestProduct?
    var selectedProducts: [FestProduct]?
    private(set) var productValidation: Validation?
    var paymentType: PaymentView.ButtonAction?
    // MARK: - OrderField
    var city: String?
    var date: String?
    private var areaes: [Area]?
    // MARK: - Functions
    func getGovernates() -> [String]? {
        let governorates = festCities?.governorates.compactMap({ governorate -> String? in
            let areas = governorate.areas.filter({ $0.areaData?.first?.minimumOrder != nil && $0.areaData?.first?.deliveryCharge != nil })
            return areas.isEmpty ? nil : governorate.governorateName
        })
        return governorates
    }
    func getGovernateArea(_ selectedGovernate: String?) -> [String]? {
        self.areaes?.removeAll()
        let areas = festCities?.governorates?.flatMap({ governorate -> [String] in
            guard governorate.governorateName == selectedGovernate else { return [] }
            let areaNames = governorate.areas.compactMap { area -> String? in
                if area.areaData?.first?.minimumOrder != nil && area.areaData?.first?.deliveryCharge != nil {
                    if self.areaes == nil {
                        self.areaes = [Area]()
                    }
                    self.areaes?.append(area)
                    return area.areaName
                }
                return nil
            }
            return areaNames
            })
        return areas
    }
    func getCharges(_ index: Int) -> Double? {
        self.areaes?.count ?? 0 > 0 ? Double(self.areaes?[index].areaData?.first?.deliveryCharge ?? 0) : nil
    }
    func getAreaId(_ index: Int) -> String {
        guard let isEmpty = self.areaes?.isEmpty, !isEmpty else {
            return ""
        }
        let areaId = self.areaes?[index].id ?? 0
        return areaId == 0 ? "" : "\(areaId)"
    }
    func getAllProductIds() -> String? {
        let ids = selectedProducts?.map({ "\($0.id ?? 0)" })
        return ids?.joined(separator: ",")
    }
    func addMultProduct(_ validatedProduct: Validation?) -> Double? {
        if productValidation?.productsParam == nil {
            productValidation = Validation()
            productValidation?.productsParam = [[String: Any]]()
        }
        if let productParam = validatedProduct?.productParam {
            productValidation?.productsParam?.append(productParam)
        }
        let productTotal = productValidation?.productsParam?.reduce(0.0, { sum, dictProduct -> Double in
            let total = sum + ((dictProduct["price"] as? Double) ?? 0.0)
            return total
        })
        return productTotal
    }
}
extension AddOrderViewModel: OrderField {
    func setFieldData() {
//        self.city
    }
}
extension AddOrderViewModel {
    class func pairdAtrributedString(_ initialText: String? = nil,
                                     initialFont: UIFont? = nil,
                                     initialColor: Color? = Color.black,
                                     pair pairdText: String? = nil,
                                     pairColor: Color? = Color.black,
                                     pairFont: UIFont? = nil ) -> NSMutableAttributedString {

        let defaultFont = Font(.installed(.RedHatDisplayRegular), size: .standard(.h24)).instance
        let yourAttributes = [NSAttributedString.Key.foregroundColor: initialColor?.value ?? UIColor.white,
                              NSAttributedString.Key.font: initialFont ?? defaultFont]
        let yourOtherAttributes = [NSAttributedString.Key.foregroundColor: pairColor?.value ?? UIColor.white,
                                   NSAttributedString.Key.font: pairFont ?? defaultFont]

        let partOne = NSMutableAttributedString(string: initialText ?? "", attributes: yourAttributes)
        let partTwo = NSMutableAttributedString(string: pairdText ?? "", attributes: yourOtherAttributes)

        let combination = NSMutableAttributedString()

        combination.append(partOne)
        combination.append(partTwo)
        return combination
    }
}
