//
//  MasterViewController.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController {
    
    // MARK: - Types
    private enum MessageLabelState: String {
        case instructions
        case loading
        case noResults
        case hidden
    }
    
    private enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
        case messageLabelText
        case currentPageNumber
    }
    
    private struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    // MARK: - Properties
    private var searchController: UISearchController!
    private var restoredState = SearchControllerRestorableState()
    var detailViewController: DetailViewController? = nil
    var container : NSPersistentContainer { return CoreDataStack.shared.persistentContainer }
    static var searchTerm: String = ""
    static var isFilteringOutNsfw: Bool = true
    private var pageNumber: Int = 0
    private var lastEntryTime: Date = Date()
    private let debounceInterval: TimeInterval = 0.25
    private var isNoResults = false
    private lazy var dataProvider: ImgurAPI = {
        let provider = ImgurAPI()
        return provider
    }()
    
    // MARK: - Outlets
    @IBOutlet weak var nsfwButton: UIBarButtonItem!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet var spinner: UIActivityIndicatorView!
    

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.autocapitalizationType = .none
        
        if #available(iOS 11.0, *) {
            // For iOS 11 and later, place the search bar in the navigation bar.
            navigationItem.searchController = searchController
            
            // Make the search bar always visible.
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // For iOS 10 and earlier, place the search controller's search bar in the table view's header.
            tableView.tableHeaderView = searchController.searchBar
        }
        
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false // The default is true.
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "photos from Imgur"
        definesPresentationContext = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateIsNoResultsTrue), name: .noResults, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateForFinishedFetch), name: .dataFetchFinished, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        var state = MessageLabelState.hidden
        if self.tableView.numberOfRows(inSection: 0) > 0 {
        }
        else if self.isNoResults {
            state = .noResults
        } else {
            state = .instructions
        }
        self.updateMessageLabel(state: state)
        
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Message Label Handling
    
    @objc func updateIsNoResultsTrue() {
        DispatchQueue.main.async {
            self.isNoResults = true
            self.tableView.reloadData()
        }
    }
    
    private func updateMessageLabel(state: MessageLabelState) {
        DispatchQueue.main.async {
            self.spinner.removeFromSuperview()
            self.messageLabel.text = self.textForMessageLabel(state: state)
            switch state {
            case .instructions:
                self.messageLabel.frame.size.height = 200
            case .loading:
                self.messageLabel.frame.size.height = 100
                self.spinner.frame = self.messageLabel.frame
                self.messageLabel.addSubview(self.spinner)
            case .noResults:
                self.messageLabel.frame.size.height = 100
            case .hidden:
                self.messageLabel.frame.size.height = 0
            }
            self.view.addSubview(self.messageLabel)
        }
    }
    
    private func textForMessageLabel(state: MessageLabelState) -> String {
        switch state {
        case .instructions:
            return """
            Feel free to search with operators
            (AND, OR, NOT)
            and indices
            (tag:, user:, title:, ext:, subreddit:, album:, meme:).
            An example compound query would be
            'title: The Searchers OR album: John Wayne'
            """
        case .loading:
            return ""
        case .noResults:
            return """
            No results.
            You might want to widen your search
            with AND, OR, etc.
            """
        case .hidden:
            return ""
        }
    }
    
    // MARK: - Table View
    
    @objc func updateForFinishedFetch() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        let rowCount = sectionInfo.numberOfObjects
        
        var state: MessageLabelState = .loading
        if rowCount > 0 {
            state = .hidden
        } else if self.isNoResults {
            state = .noResults
        } else {
            state = .instructions
        }
        self.updateMessageLabel(state: state)
        
        return rowCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> ThumbnailTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        guard let item = self.fetchedResultsController.fetchedObjects?[indexPath.row]
            else { return cell as! ThumbnailTableViewCell }
        configureCell(cell as! ThumbnailTableViewCell, withItem: item)
        
        // When the last cell is set up...
        if indexPath.row + 1 == self.fetchedResultsController.fetchedObjects?.count && !isNoResults {
            self.pageNumber += 1
            self.debouncedNetworkFetch(searchTerm: MasterViewController.searchTerm, pageNumber: self.pageNumber)
            debugPrint("Next page fetch for pageNumber = " + self.pageNumber.description)
        }
        return cell as! ThumbnailTableViewCell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func configureCell(_ cell: ThumbnailTableViewCell, withItem item: Item) {
        cell.titleLabel.text = item.title
        cell.activityIndicator?.isHidden = false
        
        if item.thumbnailData != nil {
            cell.imageView?.image = UIImage(data: item.thumbnailData!)
            cell.activityIndicator?.isHidden = true
        } else {
            guard let link = item.thumbnailLink
                else { return }
            
            DispatchQueue.global(qos:.userInitiated).async {
                if let imgURL = URL.init(string: link) {
                    do {
                        let imageData = try Data(contentsOf: imgURL as URL);
                        let image = UIImage(data:imageData);
                        
                        DispatchQueue.main.async {
                            cell.imageView?.image = image
                            cell.activityIndicator?.isHidden = true
                            
                            // Update Item with imageData.
                            item.thumbnailData = imageData
                            // Refault it so it will be refreshed the next time it is accessed.
                            // Safer but slows segue to Detail view.
                            item.managedObjectContext?.refresh(item, mergeChanges: true)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            cell.activityIndicator?.isHidden = true
                        }
                        print("Unable to load data: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Button Action
    
    @IBAction func nsfwButtonTap(_ sender: UIBarButtonItem) {
        MasterViewController.isFilteringOutNsfw = !MasterViewController.isFilteringOutNsfw
        self.nsfwButton.title = MasterViewController.isFilteringOutNsfw ? "nsfw is filtered out" : "NSFW is allowed"
        self.nsfwButton.tintColor = MasterViewController.isFilteringOutNsfw ? UIColor.orange : UIColor.red
        
        // Clear data based on old setting and perform same search with new setting.
        CoreDataStack.shared.deleteAll(entityName: "Item")
        self.tableView.reloadData()
        self.pageNumber = 0
        self.isNoResults = false
        self.updateMessageLabel(state: .loading)
        self.fetchItems(searchTerm: MasterViewController.searchTerm, pageNumber: 0)
    }
    
    // MARK: - Network Calls
    
    func debouncedNetworkFetch(searchTerm: String, pageNumber: Int = 0) {
        self.lastEntryTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.debounceInterval) {
            if self.lastEntryTime + self.debounceInterval <= Date() {
                if pageNumber == 0 {
                    CoreDataStack.shared.deleteAll(entityName: "Item")
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                self.isNoResults = false
                self.updateMessageLabel(state: .loading)
                self.fetchItems(searchTerm: MasterViewController.searchTerm, pageNumber: pageNumber)
            }
        }
    }
    
    func fetchItems(searchTerm: String = "", pageNumber: Int = 0) {
        dataProvider.fetchFor(searchTerm: searchTerm, pageNumber: pageNumber)
    }
    
    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Item> {

        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if MasterViewController.isFilteringOutNsfw {
            let predicate = NSPredicate(format: "nsfw == %d", Bool(false))
            fetchRequest.predicate = predicate
        }

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try controller.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return controller
    }
}


// MARK: - UISearchBarDelegate

extension MasterViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        MasterViewController.searchTerm = searchText
        self.pageNumber = 0
        self.debouncedNetworkFetch(searchTerm: MasterViewController.searchTerm)
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        MasterViewController.searchTerm = searchBar.text ?? ""
        self.pageNumber = 0
        self.debouncedNetworkFetch(searchTerm: MasterViewController.searchTerm)
    }
    
}

// MARK: - UISearchControllerDelegate

// Use these delegate functions for additional control over the search controller.

extension MasterViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        self.tableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

// MARK: - UIStateRestoration

extension MasterViewController {
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // Encode the view state so it can be restored later.
        
        // Encode the title.
        coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)
        
        // Encode the search controller's active state.
        coder.encode(searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        // Encode the first responser status.
        coder.encode(searchController.searchBar.isFirstResponder, forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Encode the search bar text.
        coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
        
        coder.encode(messageLabel.text, forKey: RestorationKeys.messageLabelText.rawValue)
        
        coder.encode(pageNumber, forKey: RestorationKeys.currentPageNumber.rawValue)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        // Restore the title.
        guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
            fatalError("A title did not exist. In your app, handle this gracefully.")
        }
        navigationItem.title! = decodedTitle
        
        /** Restore the active state:
         We can't make the searchController active here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        /** Restore the first responder status:
         Like above, we can't make the searchController first responder here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
        
        messageLabel.text = coder.decodeObject(forKey: RestorationKeys.messageLabelText.rawValue) as? String
        
        pageNumber = coder.decodeObject(forKey: RestorationKeys.currentPageNumber.rawValue) as? Int ?? 0
    }
}
