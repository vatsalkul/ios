//
//  SharesPresenter.swift
//  AmahiAnywhere
//
//  Created by Chirag Maheshwari on 07/03/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

protocol SharesView : BaseView {
    func updateShares(shares: [ServerShare])
    func updateRefreshing(isRefreshing: Bool)
}

class SharesPresenter: BasePresenter {
    
    weak private var view: SharesView?
    
    init(_ view: SharesView) {
        self.view = view
    }
    
    func detachView() {
        self.view = nil
    }
    
    func loadServerRoute() {
        if !ServerApi.shared!.isServerRouteLoaded{
            self.view?.updateRefreshing(isRefreshing: true)
            
            ServerApi.shared!.loadServerRoute() { (isLoadSuccessful) in
                if !isLoadSuccessful {
                    self.view?.updateRefreshing(isRefreshing: false)
                    return
                }
                
                if ServerApi.shared!.getServer()!.name == "Welcome to Amahi"{
                    ServerApi.shared!.authenticateServerWithPIN(pin: "123", completion: { (authTokenResponse) in
                        if let response = authTokenResponse, let authToken = response.auth_token{
                            ServerApi.shared!.setAuthToken(token: authToken)
                            self.getShares()
                        }else{
                            self.view?.updateRefreshing(isRefreshing: false)
                            return
                        }
                    })
                }else{
                    self.getShares()
                }
            }
        }else{
            getShares()
        }
    }
    
    func getShares() {
        
        self.view?.updateRefreshing(isRefreshing: true)
        
        ServerApi.shared!.getShares() { (serverSharesResponse) in
            
            self.view?.updateRefreshing(isRefreshing: false)
            
            guard let serverShares = serverSharesResponse else {
                return
            }
            
            self.view?.updateShares(shares: serverShares)
        }
    }
}
