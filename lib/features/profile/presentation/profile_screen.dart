import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:dream_cast/features/profile/data/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = ref.read(activeProfileProvider).asData?.value;
      if (profile != null) _controller.text = profile.name;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);

    return AppScreen(
      title: 'Профиль',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Имя профиля',
              hintText: 'Как к вам обращаться',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: profile.isLoading ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(activeProfileProvider.notifier).save(_controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль сохранён.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
