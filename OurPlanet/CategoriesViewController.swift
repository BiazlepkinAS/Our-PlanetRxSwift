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
//    eoCategories
//      .bind(to: categories)
//      .disposed(by: disposeBag)
    
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
    cell.textLabel?.text = "\(category.name) (\(category.events.count)"
    cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
    cell.detailTextLabel?.text = category.description
    
    return cell
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let category = categories.value[indexPath.row]
    tableView.deselectRow(at: indexPath, animated: true)
    
    guard !category.events.isEmpty else { return }
    let eventsController = storyboard?.instantiateViewController(withIdentifier: "events") as! EventsViewController
    eventsController.title = category.name
    eventsController.events.accept(category.events)
    navigationController?.pushViewController(eventsController, animated: true)
  }
}
