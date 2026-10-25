import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../verify_items.dart';
import 'complete_verification.dart';
import 'profile.dart';

/// Verification Summary – matches the reference design: status per item,
/// profile completion, COMPLETE PENDING VERIFICATION and role switch.
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppState.I,
        builder: (c, _) {
          final items = verificationItems();
          final pct = completionPercent(items);
          final pending = items.where((e) => !e.ok).length;
          return Scaffold(
            backgroundColor: const Color(0xFFF4F8FD),
            appBar: AppBar(title: const Text('Verification Summary')),
            body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Expanded(child: Text('Complete your details to get full access to all features.', style: TextStyle(color: C.grey, fontSize: 14))),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE1F2F7), borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_user, color: Color(0xFF14958F), size: 28),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Profile', style: TextStyle(fontSize: 12, color: C.grey)),
                      Text('Completion: $pct%', style: const TextStyle(fontWeight: FontWeight.w900, color: C.ok, fontSize: 13)),
                    ]),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE3EAF8))),
                child: Column(children: [
                  for (var i = 0; i < items.length; i++)
                    InkWell(
                      onTap: () => Navigator.push(c, profileRoute('/profile/complete', CompleteVerificationScreen(focus: items[i].key))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(border: i == items.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFEDF1FA)))),
                        child: Row(children: [
                          CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE1ECFD), child: Icon(items[i].icon, size: 20, color: C.navy)),
                          const SizedBox(width: 14),
                          Expanded(child: Text(items[i].label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.navy))),
                          Icon(items[i].ok ? Icons.check_circle : Icons.schedule, size: 20, color: items[i].color),
                          const SizedBox(width: 5),
                          Text(items[i].status, style: TextStyle(fontWeight: FontWeight.w800, color: items[i].color)),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: C.grey),
                        ]),
                      ),
                    ),
                  InkWell(
                    onTap: () => showRoleSheet(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE1ECFD), child: Icon(Icons.person, size: 20, color: C.navy)),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('User Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.navy))),
                        const Icon(Icons.groups, size: 22, color: C.royal),
                        const SizedBox(width: 6),
                        Text(AppState.I.role == 'both' ? 'Both' : roleLabel(AppState.I.role), style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
                        const Icon(Icons.chevron_right, color: C.grey),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE4F3F7), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFF14958F)),
                  SizedBox(width: 12),
                  Expanded(child: Text('You can still send an SOS even if some verifications are pending.', style: TextStyle(fontSize: 15))),
                ]),
              ),
              const SizedBox(height: 14),
              if (pending > 0)
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14958F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.push(c, profileRoute('/profile/complete', const CompleteVerificationScreen())),
                    icon: const Icon(Icons.edit),
                    label: const Text('Complete Pending Verification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEAF3FC), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.groups, color: C.royal)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Selected Role', style: TextStyle(color: C.grey, fontSize: 13)),
                    Text(AppState.I.role == 'both' ? 'Both' : roleLabel(AppState.I.role), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.navy)),
                  ])),
                  OutlinedButton.icon(
                      onPressed: () => showRoleSheet(c),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Change Role'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF14958F), side: const BorderSide(color: Color(0xFF14958F)), shape: const StadiumBorder())),
                ]),
              ),
            ]),
          );
        },
      );
}
