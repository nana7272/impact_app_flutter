
import 'package:flutter/material.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';

class ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onSearch;
  final Function(ProdukSampling) onProductSelected;
  final List<ProdukSampling> searchResults;
  final bool isSearching;
  final String? validationError;
  
  const ProductSearchField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    required this.onProductSelected,
    required this.searchResults,
    this.isSearching = false,
    this.validationError,
  }) : super(key: key);

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.validationError != null ? Colors.red : Colors.grey,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onSearch('');
                      },
                    )
                  : const Icon(Icons.clear, color: Colors.transparent),
            ),
            onChanged: widget.onSearch,
          ),
        ),
        if (widget.validationError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.validationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (widget.isSearching)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.searchResults.length,
              itemBuilder: (context, index) {
                final produk = widget.searchResults[index];
                return ListTile(
                  title: Text(produk.nama),
                  subtitle: produk.kode != null ? Text(produk.kode!) : null,
                  onTap: () => widget.onProductSelected(produk),
                );
              },
            ),
          ),
      ],
    );
  }
}