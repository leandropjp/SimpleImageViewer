import UIKit
import SimpleImageViewer

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let images = [UIImage(named: "1"),
                              UIImage(named: "2"),
                              UIImage(named: "3"),
                              UIImage(named: "4"),
                              UIImage(named: "5"),
                              UIImage(named: "6")]
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.row]
        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        present(PagingViewController(images: images.compactMap({$0}), initialIndex: indexPath.row), animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.frame.width / 3 - 8
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
