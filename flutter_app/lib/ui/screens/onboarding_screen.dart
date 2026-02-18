import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_bloc.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_event.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_state.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final TextEditingController _handleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1016),
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.message)),
              );
          }

          if (state is OnboardingComplete) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Welcome to ReddMobile!')),
              );
          }
        },
        builder: (context, state) {
          final bool isChecking = state is HandleChecking;
          final bool isCreating = state is WalletCreating;
          final bool isBusy = isChecking || isCreating;
          final bool canCreateWallet = state is HandleAvailable;

          final String buttonLabel = canCreateWallet
              ? 'Create Wallet & Secure Vault'
              : 'Claim Your ReddID';

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Claim your ReddID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pick a unique @handle to begin your wallet setup.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _handleController,
                            enabled: !isBusy,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '@handle',
                              labelStyle:
                                  TextStyle(color: Colors.white.withOpacity(0.7)),
                              hintText: 'yourname',
                              hintStyle:
                                  TextStyle(color: Colors.white.withOpacity(0.45)),
                              filled: true,
                              fillColor: const Color(0xFF0F131A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF253244),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF253244),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A2230),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4C9EFF),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (state is HandleUnavailable) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'That handle is unavailable. Try another one.',
                              style: TextStyle(
                                color: Color(0xFFFF7A7A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C9EFF),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF4C9EFF).withOpacity(0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      final String handle =
                                          _handleController.text.trim();
                                      if (handle.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a handle first.',
                                              ),
                                            ),
                                          );
                                        return;
                                      }

                                      final OnboardingBloc onboardingBloc =
                                          context.read<OnboardingBloc>();
                                      if (canCreateWallet) {
                                        onboardingBloc.add(
                                          ClaimHandleAndCreateWallet(handle),
                                        );
                                      } else {
                                        onboardingBloc.add(CheckHandle(handle));
                                      }
                                    },
                              child: isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      buttonLabel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
