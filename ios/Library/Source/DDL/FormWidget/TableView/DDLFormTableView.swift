/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/
import UIKit


public class DDLFormTableView: DDLFormView, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet internal var tableView: UITableView?

	override public var record: DDLRecord? {
		didSet {
			forEachField() {
				$0.resetCurrentHeight()
			}

			tableView!.reloadData()
		}
	}


	internal var firstCellResponder:UIResponder?

	internal var submitButtonHeight:CGFloat = 0.0


	//MARK: DDLFormView

	override public func resignFirstResponder() -> Bool {
		var result:Bool = false

		if let cellValue = firstCellResponder {
			result = cellValue.resignFirstResponder()
			if result {
				firstCellResponder = nil
			}
		}

		return result
	}

	override public func becomeFirstResponder() -> Bool {
		var result = false

		let rowCount = tableView!.numberOfRowsInSection(0)
		var indexPath = NSIndexPath(forRow: 0, inSection: 0)

		while !result && indexPath.row < rowCount {
			if let cell = tableView!.cellForRowAtIndexPath(indexPath) {
				if cell.canBecomeFirstResponder() {
					result = true
					cell.becomeFirstResponder()
				}

			}
			indexPath = NSIndexPath(forRow: indexPath.row.successor(), inSection: indexPath.section)
		}

		return result
	}

	override internal func onCreated() {
		super.onCreated()

		registerFieldCells()
	}

	override internal func showField(field: DDLField) {
		if let row = getFieldIndex(field) {
			tableView!.scrollToRowAtIndexPath(
				NSIndexPath(forRow: row, inSection: 0),
				atScrollPosition: .Top, animated: true)
		}
	}

	override internal func changeDocumentUploadStatus(field: DDLFieldDocument) {
		if let row = getFieldIndex(field) {
			if let cell = tableView!.cellForRowAtIndexPath(
					NSIndexPath(forRow: row, inSection: 0)) as? DDLFieldTableCell {
				cell.changeDocumentUploadStatus(field)
			}
		}
	}


	//MARK: UITableViewDataSource

	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isRecordEmpty {
			return 0
		}

		return record!.fields.count + (showSubmitButton ? 1 : 0)
	}

	public func tableView(tableView: UITableView,
			cellForRowAtIndexPath indexPath: NSIndexPath)
			-> UITableViewCell {

		var cell:DDLFieldTableCell?
		let row = indexPath.row

		if row == record!.fields.count {
			cell = tableView.dequeueReusableCellWithIdentifier("SubmitButton") as?
					DDLFieldTableCell

			cell!.formView = self
		}
		else if let field = getField(row) {
			cell = tableView.dequeueReusableCellWithIdentifier(
					field.editorType.toCapitalizedName()) as? DDLFieldTableCell

			if let cellValue = cell {
				cellValue.formView = self
				cellValue.tableView = tableView
				cellValue.indexPath = indexPath
				cellValue.field = field
			}
			else {
				println("ERROR: Cell XIB is not registerd for type " +
						field.editorType.toCapitalizedName())
			}
		}

		return cell!
	}

	public func tableView(tableView: UITableView,
			heightForRowAtIndexPath indexPath: NSIndexPath)
			-> CGFloat {

		let row = indexPath.row

		return (row == record!.fields.count) ? submitButtonHeight : getField(row)!.currentHeight
	}


	//MARK: Internal methods

	internal func registerFieldCells() {
		let currentBundle = NSBundle(forClass: self.dynamicType)

		for fieldEditor in DDLField.Editor.all() {
			var nibName = "DDLField\(fieldEditor.toCapitalizedName())TableCell"
			if let themeNameValue = themeName {
				nibName += "_" + themeNameValue
			}

			if currentBundle.pathForResource(nibName, ofType: "nib") != nil {
				var cellNib = UINib(nibName: nibName, bundle: currentBundle)

				tableView?.registerNib(cellNib,
						forCellReuseIdentifier: fieldEditor.toCapitalizedName())

				registerFieldEditorHeight(editor:fieldEditor, nib:cellNib)
			}
		}

		if showSubmitButton {
			var nibName = "DDLSubmitButtonTableCell"
			if let themeNameValue = themeName {
				nibName += "_" + themeNameValue
			}

			if currentBundle.pathForResource(nibName, ofType: "nib") != nil {
				var cellNib = UINib(nibName: nibName, bundle: currentBundle)

				tableView?.registerNib(cellNib, forCellReuseIdentifier: "SubmitButton")

				let views = cellNib.instantiateWithOwner(nil, options: nil)

				if let cellRootView = views.first as? UITableViewCell {
					submitButtonHeight = cellRootView.bounds.size.height
				}
				else {
					println("ERROR: Root view in submit button didn't found")
				}
			}
			else {
				println("ERROR: Can't register cell for submit button: \(nibName)")
			}
		}
	}

	internal func registerFieldEditorHeight(#editor:DDLField.Editor, nib:UINib) {
		let views = nib.instantiateWithOwner(nil, options: nil)

		if let cellRootView = views.first as? UITableViewCell {
			editor.registerHeight(cellRootView.bounds.size.height)
		}
		else {
			println("ERROR: Root view in cell \(editor.toRaw()) didn't found")
		}
	}

}