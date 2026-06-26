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
        children: items.map((item) {
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: const Color(0xFF1E3A5F)),
                title: Text(item.label),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: item.onTap,
              ),
              Divider(height: 0.5, thickness: 0.5, indent: 56, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }
}