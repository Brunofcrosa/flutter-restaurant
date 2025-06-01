// lib/modules/widgets/card_item_comanda.dart
import 'package:flutter/material.dart';
import 'dart:io';

import '../../services/db/modelo_comanda.dart';

class CardItemComanda extends StatelessWidget {
  final ItemComanda item;
  final VoidCallback aoRemover;
  final VoidCallback? aoTocar;

  const CardItemComanda({
    super.key,
    required this.item,
    required this.aoRemover,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.caminhoFoto != null && item.caminhoFoto!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(item.caminhoFoto!),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(Icons.broken_image, size: 35, color: Colors.grey[400]),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(Icons.fastfood, size: 35, color: Colors.grey[400]),
                    ),
                  const SizedBox(height: 5),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qtd: ${item.quantidade} | Preço Unit.: R\$${item.preco.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                      onPressed: aoRemover,
                      tooltip: 'Remover Item',
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}