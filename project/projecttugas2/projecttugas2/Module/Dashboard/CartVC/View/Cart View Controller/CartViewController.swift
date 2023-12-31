import UIKit
import Reachability
import FloatingPanel
import Kingfisher
import CoreData
import SkeletonView

class CartViewController: UIViewController {
    
    @IBOutlet weak var cartListTableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    var errorController: ErrorHandlingController?
    var floatingPanelController: FloatingPanelController!
    // tangkap data dari passing data tahap 5
    var fetchData: [CartModelCoffee] = [] {
        didSet {
            cartListTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCheckOut()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cartListTableView.showAnimatedSkeleton()
        fetchData = []
        fetchCoreData()
        errorController = ErrorHandlingController()
        cartListTableView.reloadData()
    }
    
    // MARK: - Configuration
    func setup() {
        
        cartListTableView.isUserInteractionEnabled = true
        cartListTableView.automaticallyAdjustsScrollIndicatorInsets = false
        cartListTableView.delegate = self
        cartListTableView.dataSource = self
        cartListTableView.registerCellWithNib(CartSec1TableViewCell.self)
        cartListTableView.registerCellWithNib(CartTableViewCell.self)
       
        cartListTableView.layoutMargins = .init(top: 10.0, left: 0, bottom: 20.0, right: 0)
        cartListTableView.separatorInset = cartListTableView.layoutMargins
        
        setupBackgroundImg()
    }
    
    func setupBackgroundImg() {
        let backgroundImage = UIImage(named: "1332")
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        self.cartListTableView.backgroundView = backgroundImageView
        backgroundImageView.alpha = 0.1
    }
}

// MARK: - UI Tableview Delegate & Data Source
extension CartViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return fetchData.count
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.bounces = false
        switch indexPath.section {
        case 0:
            let cell = cartListTableView.dequeueReusableCell(forIndexPath: indexPath) as CartSec1TableViewCell
            return cell
        case 1:
            let cell = cartListTableView.dequeueReusableCell(forIndexPath: indexPath) as CartTableViewCell
            let list = fetchData[indexPath.row]
            cell.configureContent(data: list)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let indexToRemove = indexPath.row
            tableView.beginUpdates()
            removeDataFrmCoreData(index: indexToRemove)
            self.fetchData.remove(at: indexToRemove)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let index = indexPath.row
            let selectedItemId = fetchData[indexPath.row].id
            showCheckOut(for: selectedItemId ?? 0, index: index)
        }
    }
    
    // MARK: - Bottom Sheet Floating Panel
    
    func setupCheckOut() {
        floatingPanelController = FloatingPanelController()
        floatingPanelController.delegate = self
        floatingPanelController.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        floatingPanelController.isRemovalInteractionEnabled = true
    }
    
    func showCheckOut(for item: Int?, index: Int) {
        if let selectedItem = fetchData.first(where: { $0.id == item}) {
            let floatingPanel = CheckOutViewController()
            floatingPanel.configureContent(with: selectedItem, index: index)
            floatingPanel.delegate = self
            floatingPanelController.surfaceView.appearance.cornerRadius = 20
            floatingPanelController.set(contentViewController: floatingPanel)
            floatingPanelController.addPanel(toParent: self)
            floatingPanelController.show(animated: true)
        }
    }

    // MARK: - Get & Remove Data
    
    func fetchCoreData() {
        
        guard let userID = Firebase.uid, let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        
        fetchRequest.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            if let cartItems = fetchedResults as? [NSManagedObject] {
                for item in cartItems {
                    if let name = item.value(forKey: "namaCoffee") as? String,
                       let id = item.value(forKey: "id") as? Int,
                       let image = item.value(forKey: "imgUrlCoffee") as? String,
                       let quantity = item.value(forKey: "quantityCoffee") as? Int,
                       let size = item.value(forKey: "sizeCoffee") as? String,
                       let totalHarga = item.value(forKey: "totHargaCoffee") as? Double,
                       let region = item.value(forKey: "region") as? String {
                        let item = CartModelCoffee(userID: userID, id: id, nama: name, harga: totalHarga, imgUrl: image, size: size, quantity: quantity, region: region)
                        fetchData.append(item)
                    }
                    
                }
                cartListTableView.hideSkeleton()
                DispatchQueue.main.async {
                    if !self.isConnected() {
                        self.showErrorView()
                        ToastManager.shared.showToastOnlyMessage(message: "Please check your internet connection.")
                    }
                }
            }
        } catch let error as NSError {
            print("Failed to fetch data: \(error), \(error.userInfo)")
            showErrorView()
        }
    }

    
    //    tahap 1 kasih parameter buat dapat id
    func removeDataFrmCoreData(index: Int){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            if let cartItems = fetchedResults as? [NSManagedObject]{
                let itemselected = cartItems[index]
                context.delete(itemselected)
                try context.save()
                cartListTableView.reloadData()
                ToastManager.shared.showToastOnlyMessage(message: "Success remove data")
            }
        }catch{
            ToastManager.shared.showToastOnlyMessage(message: "Failed remove data")
        }
    }
}

extension CartViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return CheckOutFloatingPanel()
    }
}

extension CartViewController: CheckoutDelegate {
    func FloatingPanelDidDismiss(index: Int) {
        fetchData = []
        fetchCoreData()
        cartListTableView.reloadData()
    }
}

extension CartViewController: SkeletonTableViewDataSource {
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 2
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return String(describing: CartTableViewCell.self)
    }
}


// MARK: - Error Handling Connection

extension CartViewController: ErrorHandlingDelegate {
    func showErrorView() {
        guard let errorVC = errorController else { return }
        
        if !isConnected() {
            errorVC.errorType = .networkError
        } else {
            errorVC.errorType = .emptyDataError
        }
        
        errorVC.delegate = self
        addChild(errorVC)
        view.addSubview(errorVC.view)
        errorVC.didMove(toParent: self)
    }
    
    func isConnected() -> Bool {
        guard let reachability = try? Reachability() else { return false }
        return reachability.connection != .unavailable
    }
    
    func didRefresh() {
        fetchCoreData()
        refreshControl.endRefreshing()
    }
}
