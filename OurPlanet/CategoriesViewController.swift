import UIKit
import RxSwift
import RxCocoa

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  let categories = BehaviorRelay<[EOCategory]>(value: [])
  let disposeBag = DisposeBag()
  
  @IBOutlet var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    categories
      .asObservable()
      .subscribe(onNext: { [weak self] _ in
        DispatchQueue.main.async {
          self?.tableView.reloadData()
        }
      })
      .disposed(by: disposeBag)
    
    startDownload()
  }
  
  func startDownload() {
    let eoCategories = EONET.categories
    let downloadEvents = EONET.events(forLast: 360)
    eoCategories
      .bind(to: categories)
      .disposed(by: disposeBag)
    let updateCategories = Observable
      .combineLatest(eoCategories, downloadEvents) {
        (categories, events) -> [EOCategory] in
        return categories.map { category in
          var cat = category
          cat.events = events.filter {
            $0.categories.contains(where: { $0.id == category.id })
          }
          return cat
        }
      }
    eoCategories
      .concat(updateCategories)
      .bind(to: categories)
      .disposed(by: disposeBag)
  }
  
  // MARK: UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return categories.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
    let category = categories.value[indexPath.row]
    cell.textLabel?.text = category.name
    cell.detailTextLabel?.text = category.description
    
    return cell
  }
}
