import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];
  String _authToken;
  String _userId;

  // var _showFavoritesOnly = false;

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((item) => item.isFavorite == true).toList();
    // }
    return [..._items];
  }

  set authToken(String value) {
    _authToken = value;
  }

  set userId(String value) {
    _userId = value;
  }

  List<Product> get favoriteItems {
    return _items.where((item) => item.isFavorite == true).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((item) => item.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    var url = Uri.parse(
        'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/products.json?auth=$_authToken&$filterString');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }

      url = Uri.parse(
          'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/userFavourites/$_userId.json?auth=$_authToken');

      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);

      final List<Product> loadedProducts = [];

      extractedData.forEach(
        (prodId, prodData) {
          loadedProducts.add(
            Product(
              id: prodId,
              title: prodData['title'],
              description: prodData['description'],
              price: prodData['price'],
              imageUrl: prodData['imageUrl'],
              isFavorite:
                  favoriteData == null ? false : favoriteData[prodId] ?? false,
            ),
          );
        },
      );
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  // Future<void> addProduct(Product product) {
  //   final url = Uri.parse(
  //       'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/products.json?auth=$_authToken');

  //   return http
  //       .post(
  //     url,
  //     body: json.encode(
  //       {
  //         'title': product.title,
  //         'description': product.description,
  //         'imageUrl': product.imageUrl,
  //         'price': product.price,
  //         'isFavorite': product.isFavorite,
  //       },
  //     ),
  //   )
  //       .then(
  //     (response) {
  //       final newProduct = Product(
  //         title: product.title,
  //         description: product.description,
  //         price: product.price,
  //         imageUrl: product.imageUrl,
  //         id: json.decode(response.body)['name'],
  //       );
  //       _items.add(newProduct);
  //       // _items.insert(0, newProduct); // at the start of the list
  //       notifyListeners();
  //     },
  //   ).catchError((error) {
  //     print(error);
  //     throw error;
  //   });
  // }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse(
        'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/products.json?auth=$_authToken');

    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'creatorId': _userId,
          },
        ),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);

      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.parse(
          'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/products/$id.json?auth=$_authToken');

      await http.patch(
        url,
        body: json.encode(
          {
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          },
        ),
      );

      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
        'https://aniketos-flutter-shop-app-default-rtdb.europe-west1.firebasedatabase.app/products/$id.json?auth=$_authToken');
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }

    existingProduct = null;
  }
}
