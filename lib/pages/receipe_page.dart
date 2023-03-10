import 'package:flutter/material.dart';
import 'package:kombucha_app/datamanager.dart';
import 'package:kombucha_app/datamodel.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class ReceipePage extends StatelessWidget {
  final DataManager dataManager;
  const ReceipePage({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return Receipe(dataManager: dataManager);
  }
}

class Receipe extends StatelessWidget {
  final DataManager dataManager;
  const Receipe({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
          future: dataManager.getReceipe(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var steps = snapshot.data!;
              return ListView.builder(
                  itemCount: steps.length,
                  itemBuilder: ((context, index) {
                    return ReceipeItem(
                      step: steps[index],
                      isLastStep: steps.length - 1 == index,
                    );
                  }));
            } else {
              if (snapshot.hasError) {
                developer.log(
                  'Failed to fetch receipe data',
                  error: jsonEncode(snapshot.error),
                );
                return const Text('There was an error');
              } else {
                return const CircularProgressIndicator();
              }
            }
          }),
    );
  }
}

class ReceipeItem extends StatelessWidget {
  final ReceipeStep step;
  final bool isLastStep;

  const ReceipeItem({super.key, required this.step, required this.isLastStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("${step.step}. ${step.description}",
              // style: Theme.of(context).textTheme.bodyMedium,
              style: const TextStyle(fontSize: 16.0, height: 1.5)),
        ),
        if (!isLastStep) const Divider()
      ],
    );
  }
}
