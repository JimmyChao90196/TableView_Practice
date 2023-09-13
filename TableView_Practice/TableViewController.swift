//
//  TableViewController.swift
//  TableView_Practice
//
//  Created by JimmyChao on 2023/9/13.
//

import UIKit

// MARK: - The model for this tableView
//Section has to be Hashable, in order to be used in diffibale data source
    enum Section{
        case eldenRring
        case sekiro
    }


//Each model has to be Hashable, same reason as above
struct User: Hashable{
    let name: String
    
}

//Create an array of names for each model
let names = ["Tarnished", "Greater Will", "Rani", "Marika", "Radagon", "Ezio", "Genichiro", "Ishin", "Emma", "Sekiro"]
var users = [User]()


//Reorder the model list
func reorderUserList(move userToMove: User, to userAtDestination: User) {
    let destinationIndex = users.firstIndex(of: userAtDestination) ?? 0
    users.removeAll { $0.name == userToMove.name }
    users.insert(userToMove, at: destinationIndex)
}




// MARK: - Main tableView class
class TableViewController: UITableViewController {
    
    private let alertService = AlertService()

    //Now feed in you Section and User to the data source, and made sure they are both hashable.
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

        
        initTableView()
    }
    
    
    

    //Initialize table view
    func initTableView(){
        
        //Create name for each user model
        names.forEach { name in
            let user = User(name: name)
            users.append(user)
        }
        
        self.navigationController?.isToolbarHidden = false
        
        configDataSource()
        dataSource.addUser(from: users)
        sortAscend()
    }
    
    
    
    // MARK: - Config your data source
    //Just like cell for raw at index path we too need to config the cell and return it
    private func configDataSource(){
        dataSource = UserDataSource(tableView: tableView, cellProvider: { tableView, indexPath, user in
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            
            cell.textLabel?.text = user.name
            return cell
        })

       
    }
    
    
    //MARK: - Sorting method
    @objc func sortAscend(){
        users.sort {$0.name < $1.name}
        dataSource.addUser(from: users)
    }
    
    
    @objc func sortDescend(){
        users.sort {$0.name > $1.name}
        dataSource.addUser(from: users)
    }
    
    
    
    
    
    
    
    //MARK: - Add new users and append to the model array
    @objc func didTapAddButton(){
        let alert = alertService.createUserAlert { name in
            self.addNewUser(with: name)
        }
        present(alert, animated: true)
    }
    
    
    func addNewUser(with name: String){
        let user = User(name: name)
        users.append(user)
        
        print(users.first?.name ?? "")
        
        dataSource.addUser(from: users)
    }
    
    

    
    
    //MARK: -Grab data
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = dataSource.itemIdentifier(for: indexPath) else { return }
        print(user)
    }
}




// MARK: - Self defined dataSource.
class UserDataSource: UITableViewDiffableDataSource<Section, User> {
    func addUser(from users: [User]){
        //Snapshot is much like commit diffable data source take this current commit(snapshot) and previous commit inorder to figure out what's the different between those two.
        //After the comparison process above, it will merge commits(snapshot) together without conflict. Not like the old one.
        //No more tableView misleading reload data that kind of stuff here.
        var newSnapshot = NSDiffableDataSourceSnapshot<Section, User>()
        
        newSnapshot.appendSections([Section.eldenRring])
        newSnapshot.appendItems(users)
        apply(newSnapshot, animatingDifferences: true)
    }
    
    
    func deleteUser(delete user: User){
        var newSnapshot = self.snapshot()
        
        //newSnapshot.deleteSections([Section.main])
        newSnapshot.deleteItems([user])
        apply(newSnapshot, animatingDifferences: true)
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
    
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    
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
