//
//  ViewController.swift
//  ScorpCase
//
//  Created by sercan günönü on 10.08.2021.
//

import UIKit

class PeopleList: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var peopleListTableView: UITableView!
    
    var peopleList : [Person] = []
    var pagingNext : String? = nil
    var pagination = 0
    var seenIds = Set<Int>()
    var nonDuplicates = [Person]()
    var spinner = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPeople()
        peopleListTableView.dataSource = self
        peopleListTableView.delegate = self
        
        peopleListTableView.refreshControl = UIRefreshControl()
        peopleListTableView.refreshControl!.addTarget(self, action: #selector(fetchPeople), for: UIControl.Event.valueChanged)
        
    }
    
    @objc func fetchPeople(){
        
        DataSource.fetch(next: pagingNext) { FetchResponse, FetchError in
            if FetchError != nil{
                let alert = UIAlertController(title: "Error", message: FetchError?.errorDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.fetchPeople()
                    self.peopleListTableView.isHidden = false
                }))
                
                self.present(alert, animated: true, completion: nil)
                
                self.peopleListTableView.refreshControl?.endRefreshing()
                self.peopleListTableView.reloadData()
            }else {
                //if pagination == 0 refresh the list else adds more person to the list
                if self.pagination == 0 {
                    
                    self.seenIds.removeAll()
                    self.nonDuplicates.removeAll()
                    self.peopleList.removeAll()
                    
                    self.peopleList = FetchResponse!.people
                    self.pagingNext = FetchResponse?.next
                    
                    self.findNonDuplicates()
                    
                    if self.peopleList.count == 0 {
                        
                        self.peopleListTableView.isHidden = true
                        let alert = UIAlertController(title: "No One Here", message: "Click OK Button to Refresh List", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{ action in
                            self.fetchPeople()
                            self.peopleListTableView.isHidden = false
                        } ))
                        self.present(alert, animated: true, completion: nil)
                    }
    
                    self.peopleListTableView.refreshControl?.endRefreshing()
                    DispatchQueue.main.async {
                        self.peopleListTableView.reloadData()
                    }
                }else {
                    self.peopleList.append(contentsOf: FetchResponse!.people)
                    self.pagingNext = FetchResponse?.next
                    
                    self.findNonDuplicates()
                    DispatchQueue.main.async {
                        self.peopleListTableView.reloadData()
                        self.peopleListTableView.tableFooterView = nil
                    }
                    

                    self.pagination = 0
                }
            }
        }
    }
    
    func findNonDuplicates(){
        for people in self.peopleList {
            if !self.seenIds.contains(people.id) {
                self.nonDuplicates.append(people)
                self.seenIds.insert(people.id)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nonDuplicates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PeopleListTableCell
        
        cell.fullnameLbl.text = nonDuplicates[indexPath.row].fullName + " " + "(" + String((nonDuplicates[indexPath.row].id)) + ")"
        
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let position = scrollView.contentOffset.y
        
        peopleListTableView.tableFooterView?.isHidden = false
        
        if position > (peopleListTableView.contentSize.height - scrollView.frame.size.height){
            pagination = 1
            fetchPeople()
            peopleListTableView.tableFooterView = createSpinnerFooter()
        }
    }
    func createSpinnerFooter() -> UIView{
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        
        let spinner = UIActivityIndicatorView()
        spinner.center = footerView.center
        footerView.addSubview(spinner)
        spinner.startAnimating()
        
        return footerView
        
    }
}

