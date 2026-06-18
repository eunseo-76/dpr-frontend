import 'package:flutter/material.dart';

class MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class MenuCard extends StatelessWidget {
  final List<MenuItem> items;

  const MenuCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;

          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: const Color(0xFF1E3A5F)),
                title: Text(item.label),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}