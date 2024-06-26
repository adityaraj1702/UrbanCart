import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_mall/models/product.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  CartProvider() {
    fetchCartItems();
  }

  List<CartItem> get cartItems => _cartItems;

  Future<void> fetchCartItems() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cartItems')
            .get();

        _cartItems = snapshot.docs
            .map(
              (doc) => CartItem(
                productId: doc.id,
                quantity: doc['quantity'],
              ),
            )
            .toList();
        await _fetchCartProducts();
      }
    } catch (e) {
      print(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchCartProducts() async {
    try {
      await FirebaseFirestore.instance
          .collection('productList')
          .get()
          .then((value) {
        for (CartItem cartItem in _cartItems) {
          final doc = value.docs.firstWhere(
              (result) => result.data()['id'] == cartItem.productId);
          cartItem.product = Product.fromFirestore(doc.data());
        }
      });
    } catch (e) {
      print(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> addProductToCart(Product product) async {
    final existingCartItem = _cartItems.firstWhere(
      (cartItem) => cartItem.productId == product.id,
      orElse: () => CartItem(productId: product.id, quantity: 0),
    );
    if (existingCartItem.quantity > 0) {
      existingCartItem.product = product;
      increaseQuantity(existingCartItem);
    } else {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          existingCartItem.quantity++;
          existingCartItem.product = product;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cartItems')
              .doc(product.id)
              .set({'quantity': existingCartItem.quantity});
          _cartItems.add(existingCartItem);
          notifyListeners();
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> increaseQuantity(CartItem cartItem) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        cartItem.quantity++;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cartItems')
            .doc(cartItem.productId)
            .update({'quantity': cartItem.quantity});

        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> decreaseQuantity(CartItem cartItem) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (cartItem.quantity > 1) {
          cartItem.quantity--;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cartItems')
              .doc(cartItem.productId)
              .update({'quantity': cartItem.quantity});
        }
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> removeProductFromCart(CartItem cartItem) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _cartItems.remove(cartItem);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cartItems')
            .doc(cartItem.productId)
            .delete();
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  void clearCartOnLogout() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> deleteCart() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cartItems')
            .get()
            .then((value) {
          for (DocumentSnapshot doc in value.docs) {
            doc.reference.delete();
          }
        });
        _cartItems.clear();
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  double get totalPrice {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.product?.price ?? 0) * item.quantity);
  }
}

class CartItem {
  final String productId;
  Product? product;
  int quantity;

  CartItem({
    required this.productId,
    required this.quantity,
  });
}
