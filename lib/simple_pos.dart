import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:rms_app/frontend/bloc/pos_bloc.dart';

class SimplePosScreen extends StatelessWidget {
  const SimplePosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<MenuBloc>()),
        BlocProvider.value(value: context.read<PosBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('POS Test')),
        body: const Center(child: Text('Working!')),
      ),
    );
  }
}