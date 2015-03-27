//
//  IMGTreeController.swift
//  SwiftTreeTable
//
//  Created by Geoff MacDonald on 3/26/15.
//  Copyright (c) 2015 Geoff MacDonald. All rights reserved.
//

import UIKit

@objc(IMGTreeControllerDelegate)
protocol IMGTreeControllerDelegate {
    func cell(node: IMGTreeNode, indexPath: NSIndexPath) -> UITableViewCell
    func collapsedCell(node: IMGTreeNode, indexPath: NSIndexPath) -> UITableViewCell
    optional func actionCell(node: IMGTreeNode, indexPath: NSIndexPath) -> UITableViewCell
    optional func selectionCell(node: IMGTreeNode, indexPath: NSIndexPath) -> UITableViewCell
}

@objc(IMGTreeController)
class IMGTreeController: NSObject, UITableViewDataSource{
    
    var delegate: IMGTreeControllerDelegate!
    var tableView: UITableView!
    var tree: IMGTree? {
        didSet {
            if tree != nil {
                tree!.rootNode.isVisible = true
                setNodeChildrenVisiblility(tree!.rootNode, visibility: true)
            }
            tableView.reloadData()
        }
    }
    var transactionInProgress: Bool {
        didSet {
            if transactionInProgress == false {
                commit()
            } else {
                insertedNodes = []
                deletedNodes = []
            }
        }
    }
    var insertedNodes: [IMGTreeNode] = []
    var deletedNodes: [IMGTreeNode] = []
    
    //MARK: initializers
    
    required init(tableView: UITableView, delegate: IMGTreeControllerDelegate) {
        self.tableView = tableView
        self.delegate = delegate
        transactionInProgress = false
        super.init()
        tableView.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "visibilityChanged:", name: "isVisibleChanged", object: nil)
    }
    
    //MARK: Public
    
    
    func setNodeChildrenVisiblility(node: IMGTreeNode, visibility: Bool) {
        
        if !visibility {
            for child in reverse(node.children) {
                child.isVisible = visibility
            }
        } else {
            for child in node.children {
                child.isVisible = true
            }
        }
    }
    
    func didSelectRow(indexPath: NSIndexPath) {
        if let node = tree?.rootNode.visibleNodeForIndex(indexPath.row) {
            if !node.isKindOfClass(IMGTreeSelectionNode) && !node.isKindOfClass(IMGTreeActionNode) {
                transactionInProgress = true
                addSelectionNodeIfNecessary(node)
                setNodeChildrenVisiblility(node, visibility: node.children.first?.isVisible != true ?? false)
                transactionInProgress = false
            }
        }
    }
    
    
    //MARK: Private
    
    func addSelectionNodeIfNecessary(parentNode: IMGTreeNode) {
        
        if !parentNode.isSelected {
            let selectionNode = IMGTreeSelectionNode(parentNode: parentNode)
            parentNode.addChild(selectionNode)
        }
    }
    
    func visibilityChanged(notification: NSNotification!) {
        let node = notification.object! as IMGTreeNode
        if node.isVisible {
            insertedNodes.append(node)
        } else {
            deletedNodes.append(node)
        }
    }
    
    func commit() {
        
        tableView.beginUpdates()
        
        var addedIndices: [NSIndexPath] = []
        for node in insertedNodes {
            if let rowIndex = node.visibleTraversalIndex() {
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                addedIndices.append(indexPath)
            }
            addedIndices.extend(node.indicesForTraversal())
        }
        tableView.insertRowsAtIndexPaths(addedIndices, withRowAnimation: .Top)
        
        var deletedIndices: [NSIndexPath] = []
        for node in deletedNodes {
            if let rowIndex = node.previousVisibleIndex {
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                deletedIndices.append(indexPath)
            }
            deletedIndices.extend(node.previousVisibleChildren!)
        }
        tableView.deleteRowsAtIndexPaths(deletedIndices, withRowAnimation: .Top)
        
        
        tableView.endUpdates()
    }
    

    //MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        assert(tree != nil, "!! no tree set for indexPath: " + indexPath.description)
        return delegate.cell(tree!.rootNode.visibleNodeForIndex(indexPath.row)!, indexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tree?.rootNode.visibleTraversalCount() ?? 0
    }
}
