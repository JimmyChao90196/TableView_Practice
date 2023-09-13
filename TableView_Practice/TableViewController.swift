//
//  TableViewController.swift
//  TableView_Practice
//
//  Created by JimmyChao on 2023/9/13.
//

import UIKit

// MARK: - Our data model for this tableView
//Section has to be Hashable, in order to be used in diffibale data source
    enum Section{
        case main
    }


//Each model has to be Hashable, same reason as above
struct User: Hashable{
    let name: String
    
}

//Create an array of names for your model
let names = ["Tarnished", "Greater Will", "Rani", "Marika", "Radagon", "Ezio", "Genichiro", "Ishin", "Emma", "Sekiro"]
var users = [User]()








// MARK: - Main tableView class
class TableViewController: UITableViewController {
    
    private let alertService = AlertService()

    var dataSource: UserDataSource!
    
    
    
    
    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        

        //Initialize tool bar and navigation bar item.
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        
        let ascendButton = UIBarButtonItem(image: UIImage(systemName: "chevron.up.square"), style: .plain, target: self, action: #selector(sortAscend))
        let descendButton = UIBarButtonItem(image: UIImage(systemName: "chevron.down.square"), style: .plain, target: self, action: #selector(sortDescend))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        toolbarItems = [ascendButton, flexSpace, descendButton]

        //Initialize tableView
        initTableView()
    }
    
    
    

    //Initialize tableView
    func initTableView(){
        //Create name for each user model
        names.forEach { name in
            let user = User(name: name)
            users.append(user)
        }
        
        //Unhide the tool bar
        self.navigationController?.isToolbarHidden = false
        
        //Initialize data source, create first snapshot, and call sorting method at the beginning.
        configDataSource()
        dataSource.addUser(from: users)
        //sortAscend()
    }
    
    
    
    // MARK: - Config your data source
    //Just like cellForRawAt tableView dataSource method we've been using all along, we also need to configure the cell and return to our data source class.
    private func configDataSource(){
        dataSource = UserDataSource(tableView: tableView, cellProvider: { tableView, indexPath, user in
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            
            cell.textLabel?.text = user.name
            return cell
        })
    }
    
    
    
    
    //MARK: - Sorting method
    
    //Sort users ascend
    @objc func sortAscend(){
        users.sort {$0.name < $1.name}
        users.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        dataSource.addUser(from: users)
    }
    
    //Sort users descend
    @objc func sortDescend(){
        users.sort {$0.name > $1.name}
        dataSource.addUser(from: users)
    }
    
    
    
    
    
    
    
    
    
    //MARK: - Add new users
    
        @objc func didTapAddButton(){
        let alert = alertService.createUserAlert { name in
        
            let user = User(name: name)
            users.append(user)
            self.dataSource.addUser(from: users)
            
        }
        present(alert, animated: true)
    }
    

    
    
    //MARK: -Grab data
    //We're still able to use didSelectRowAt method that table view delegate gives us
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = dataSource.itemIdentifier(for: indexPath) else { return }
        print(user)
    }
     
}





// MARK: - Self defined dataSource.
class UserDataSource: UITableViewDiffableDataSource<Section, User> {
    
    //Add new item to snapshot
    func addUser(from users: [User]){
        var newSnapshot = NSDiffableDataSourceSnapshot<Section, User>()
        newSnapshot.appendSections([Section.main])
        newSnapshot.appendItems(users)
        apply(newSnapshot, animatingDifferences: true)
    }
    
    
    //Delete item in snapshot
    func deleteUser(delete user: User){
        var newSnapshot = self.snapshot()
        newSnapshot.deleteItems([user])
        apply(newSnapshot, animatingDifferences: true)
    }
    
    
    
    //Reorder the model list
    func reorderUserList(move userToMove: User, to userAtDestination: User) {
        let destinationIndex = users.firstIndex(of: userAtDestination) ?? 0
        users.removeAll { $0.name == userToMove.name }
        users.insert(userToMove, at: destinationIndex)
        
    }
    
    
    
    
    //MARK: - Override table view functions
    
    
    //To edit row, we first need to enable the editbility
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    //The function below enable the swipe to delete ablility
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            guard let userToDelete = self.itemIdentifier(for: indexPath) else { return }
            
            if let index = users.firstIndex(where: { User in
                User.name == userToDelete.name
            }) { users.remove(at: index) }
            
            //Delete Action
            self.deleteUser(delete: userToDelete)
        }
    }
    
    
    //Same as editing row, this function below allow us to move row.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
    //And the function right here, gives us the parameters for beginning and destination for user row.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath,
                sourceIndexPath.section == destinationIndexPath.section,
                let userToMove = itemIdentifier(for: sourceIndexPath),
                let userAtDestination = itemIdentifier(for: destinationIndexPath)
                else { apply(snapshot(), animatingDifferences:  false)
            return }
        
        reorderUserList(move: userToMove, to: userAtDestination)
        addUser(from: users)
    }
     
}
