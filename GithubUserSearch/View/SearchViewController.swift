//
//  SearchViewController.swift
//  GithubUserSearch
//
//  Created by joonwon lee on 2022/05/25.
//

import UIKit
import Combine

class SearchViewController: UIViewController {
    
    let network = NetworkService(configuration: .default)
    @Published private(set) var users : [SearchResult] = []
    var subscriptions = Set<AnyCancellable>()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    typealias Item = SearchResult
    var datasource : UICollectionViewDiffableDataSource<Section,Item>!
    enum Section{
        case main
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedSearchControl()
        configureCollectinView()
        bind()
    }
    
    private func embedSearchControl(){
        self.navigationItem.title = "Search"
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = "Sonny-Kor"
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        self.navigationItem.searchController = searchController
    }
    private func configureCollectinView(){
        datasource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as? ResultCell else{
                return nil
            }
            cell.user.text = item.login
            return cell
        })
        collectionView.collectionViewLayout = layout()
    }
    private func layout() -> UICollectionViewCompositionalLayout{
        
        
        let itemsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
        let item = NSCollectionLayoutItem(layoutSize: itemsize)
        let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupsize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    private func bind(){
        $users
            .receive(on: RunLoop.main)
            .sink { users in
                var snapshot = NSDiffableDataSourceSnapshot<Section,Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(users, toSection: .main)
                self.datasource.apply(snapshot)
            }
            .store(in: &subscriptions)
    }
}
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let keycode = searchController.searchBar.text
        print("Search : \(keycode)")
    }
    
}
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let keyword = searchBar.text else { return }
//        let base = "https://api.github.com/"
//        let path = "search/users"
//        let params :[String: String] = ["q": keyword]
//        let header : [String: String] = ["Content-Type" : "application/json"]
//        var urlComponent = URLComponents(string: base + path)!
//        var queryItem = params.map { (key: String, value: String) in
//            return URLQueryItem(name: key, value: value)
//        }
//        urlComponent.queryItems = queryItem
//        var request = URLRequest(url: urlComponent.url!)
//        header.forEach { (key: String, value: String) in
//            request.addValue(value, forHTTPHeaderField: key)
//        }
        let resource = Resource<SearchUserResponse>(
            base: "https://api.github.com/",
            path: "search/users",
            params: ["q": keyword],
            header: ["Content-Type" : "application/json"])
        network.load(resource)
            .map{ $0.items }
            .replaceError(with: [])
            .receive(on: RunLoop.main)
            .assign(to: \.users, on: self)
            .store(in: &subscriptions)
        
        
//        URLSession.shared.dataTaskPublisher(for: request)
//            .map{ $0.data }
//            .decode(type: SearchUserResponse.self , decoder: JSONDecoder())
//            .map{ $0.items}
//            .replaceError(with: [])
//            .receive(on: RunLoop.main)
//            .assign(to: \.users, on: self)
//            .store(in: &subscriptions)
        
        print("button clicked \(searchBar.text)")
    }
}

