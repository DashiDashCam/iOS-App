//
//  MediaCollectionViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/20/17.
//  Copyright © 2017 Dashi. All rights reserved.
//

import UIKit
import Photos
import CoreMedia

extension CMTime {
    var durationText:String {
        let totalSeconds = CMTimeGetSeconds(self)
        let seconds:Int = Int(totalSeconds .truncatingRemainder(dividingBy: 60))
        return String(format: "%02i sec", seconds)
    }
}

protocol MediaCollectionDelegateProtocol {
    func mediaSelected(selectedAssets:[String:PHAsset])
}

private let reuseIdentifier = "Cell"

class MediaCollectionViewController: UICollectionViewController {
    
    var assets = [PHAsset]()
    var selectedAssets = [String:PHAsset]()
    var delegate:MediaCollectionDelegateProtocol!
    
    let firstItemInserted:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
        
        let asset = self.assets[indexPath.row] as PHAsset
        let thumbnail = PhotoManager().getAssetThumbnail(asset: asset)
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.size.height))
        imageView.image = thumbnail
        cell.addSubview(imageView)
        cell.sendSubview(toBack: imageView)
        
        let detailView = UIView(frame: CGRect(x: 0, y: cell.frame.size.height / 2, width: cell.frame.size.width, height: cell.frame.size.height / 2))
        detailView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        let durationLabel = UILabel(frame: CGRect(x: 0, y: detailView.frame.size.height / 4, width: detailView.frame.size.width, height: 50))
        durationLabel.textColor = UIColor.white
        
        PhotoManager().fetchAVAssetForPHAsset(videoAsset: asset) { (success, url) in
            //
            if success {
                let avasset = AVAsset(url: url)
                let duration = avasset.duration.durationText
                
                DispatchQueue.main.async {
                    durationLabel.text = "Duration: " + duration
                }
                
            }
        }
        
        detailView.addSubview(durationLabel)
        
        cell.addSubview(detailView)
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {

        self.selectedAssets.updateValue(self.assets[indexPath.row], forKey: "asset")
        delegate.mediaSelected(selectedAssets: self.selectedAssets)
        self.dismiss(animated: true, completion: nil)
        
        
        return true
    }
    

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
