import UIKit
import RxSwift

class CoffeeOutletController: UIViewController {
    
    @IBOutlet weak var outletTableView: UITableView!
    
    let viewModel = CoffeeOutletViewModel()
    let bag = DisposeBag()
    var coffeeOutlet: Outlet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindData()
        configureNavigationBar()
    }
    
    // MARK: - FUNTION
    
    func setupUI() {
        navigationItem.title = "Outlet"
        outletTableView.delegate = self
        outletTableView.dataSource = self
        outletTableView.registerCellWithNib(OutletCell.self)
    }
    
    func configureNavigationBar() {
        navigationController?.isNavigationBarHidden = false
    }
    
    func bindData() {
        viewModel.loadData()
        
        viewModel.loadingState.asObservable().subscribe(onNext: { [weak self] loading in
            guard let self = self else {return}
            
            switch loading {
            case .loading:
                print("Loading")
            case .finished:
                DispatchQueue.main.async {
                    self.outletTableView.reloadData()
                }
            case .failure:
                print("gagal")
            }
            
        }).disposed(by: bag)
        
        viewModel.coffeeOutlet.asObservable().subscribe(onNext: { [weak self] data in
            guard let self = self else { return }
            if let data = data {
                self.coffeeOutlet = data
            }
        }).disposed(by: bag)
    }
}

extension CoffeeOutletController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coffeeOutlet?.coffeeoutlet?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = outletTableView.dequeueReusableCell(forIndexPath: indexPath) as OutletCell
        if let list = coffeeOutlet?.coffeeoutlet?[indexPath.row] {
            cell.configureContent(data: list)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedItem = coffeeOutlet?.coffeeoutlet?[indexPath.row] {
            let vc = MapsOutlet()
            vc.selectedCoffeeOutlet = selectedItem
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
