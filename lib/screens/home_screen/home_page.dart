import 'package:e_mall/models/product.dart';
import 'package:e_mall/providers/category_provider.dart';
import 'package:e_mall/widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Cart'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isCategoryLoading) {
            categoryProvider.fetchCategories();
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categoryList.isEmpty) {
            return const Center(child: Text('No categories available.'));
          }

          return Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Our Products",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    categoryProvider.categoryList.length,
                    (index) {
                      bool isSelected = index == categoryProvider.selectedIndex;
                      return GestureDetector(
                        onTap: () {
                          categoryProvider.selectCategory(index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Theme.of(context).cardColor
                                    : Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.all(5),
                          child: SizedBox(
                            width: 150,
                            height: 40,
                            child: Center(
                              child: Text(
                                categoryProvider.categoryList[index],
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
              const Divider(color: Colors.grey),
              Builder(builder: (context) {
                if (categoryProvider.isProductsLoading) {
                  categoryProvider.fetchProducts();
                  return const Text('product loading...');
                }
                List<Product> filteredProducts =
                    categoryProvider.filterProducts(categoryProvider
                        .categoryList[categoryProvider.selectedIndex]);
                print("filtered product length");
                print(filteredProducts.length);
                return Expanded(
                  child: filteredProducts.isEmpty
                      ? const Text('filtered product empty')
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 313,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductTile(
                              product: filteredProducts[index],
                            );
                          },
                        ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
