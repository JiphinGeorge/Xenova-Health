import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/profile_photo_picker.dart';

/// Screen displaying the user's profile information and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.spacingXl),
                  const Center(child: ProfilePhotoPicker(radius: 64)),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    user.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacing3xl),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.emoji_events),
                          title: const Text('Achievements & Level'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.achievements),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_back),
                          title: const Text('Progress Photos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.progressPhotos),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.account_circle_outlined),
                          title: const Text('Account Details'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bar_chart),
                          title: const Text('Analytics'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.reports),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          title: const Text('Export Data'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.exportData),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () {
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
