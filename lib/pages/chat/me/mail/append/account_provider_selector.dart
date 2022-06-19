import 'package:colla_chat/pages/chat/me/mail/append/providers.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/localization.dart';

class AccountProviderSelector extends StatelessWidget {
  final void Function(Provider? provider) onSelected;
  const AccountProviderSelector({Key? key, required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.instance;
    final providers = providerService.providers;

    return ListView.separated(
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: TextButton(
              child: Text(localizations.text('accountProviderCustom')),
              onPressed: () => onSelected(null),
            ),
          );
        }
        final provider = providers[index - 1];
        return Center(
          child: provider.buildSignInButton(
            context,
            onPressed: () => onSelected(provider),
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: providers.length + 1,
    );
  }
}
