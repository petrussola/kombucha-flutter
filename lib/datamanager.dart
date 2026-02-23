import 'datamodel.dart';

class DataManager {
  List<ReceipeStep>? _receipe;

  static const List<Map<String, dynamic>> _staticData = [
    {
      "id": 1,
      "step": 1,
      "description":
          "Place desired amount of water in a clean pot and bring to boil. Once it boils remove from stove."
    },
    {
      "id": 2,
      "step": 2,
      "description":
          "Add sugar to the water. You can use the handy proportions calculator in this website to know how much sugar you need for the amount of water you are using. Important: place sugar after removing from stove, otherwise sugar will caramelise and we don't want that. Stir water to help sugar disolve."
    },
    {
      "id": 3,
      "step": 3,
      "description":
          "Add the tea bags. Again, you can use the ingredient proportions calculator in this website to know how much tea do you need."
    },
    {
      "id": 4,
      "step": 4,
      "description":
          "Cover pot and leave until cool. It is important to wait until the water has cooled down - otherwise you will kill the SCOBY (I normally prepare this step at night and leave to cool down overnight)."
    },
    {
      "id": 5,
      "step": 5,
      "description":
          "In parallel, sterilise the glass jar where fermentation will take place. There are millions of videos in YouTube how to do it, I recommend you head there for inspiration."
    },
    {
      "id": 6,
      "step": 6,
      "description":
          "Once water has cooled down, remove tea bags and transfer liquid to glass container for fermentation."
    },
    {
      "id": 7,
      "step": 7,
      "description":
          "Place SCOBY in the container. Important: I recommend handling the SCOBY with vinyl gloves or, if you don't have, very clean hands."
    },
    {
      "id": 8,
      "step": 8,
      "description":
          "Add the unflitered apple cider vinegar. Please use the proportions calculator to know how much you need."
    },
    {
      "id": 9,
      "step": 9,
      "description":
          "Cover with a kitchen paper towel, secure with an elastic band and place fermentation container in a dry, dark and aerated place. These are the optimal conditions for the SCOBY to do the fermentation. A kitchen cupboard has worked well for me."
    },
    {
      "id": 10,
      "step": 10,
      "description":
          "Wait for 14 days. The SCOBY will start floating after few days and the cupboard will start smelling of vinegar. I recommend start tasting the kombutcha after 12 days and you move to the next step once you are satisifed with the taste. If you don't know how it should taste because it is your first day, I recommend moving to the next stage at day 14."
    },
    {
      "id": 11,
      "step": 11,
      "description":
          "The SCOBY will probably have grown a new one on top of it. That is normal! Now you have an extra one to share with someone else :) Using vinyl gloves, remove SCOBY and place it on a clean plate. Transfer liquid to a bottle or wherever you wish to consume kombutcha from."
    },
    {
      "id": 12,
      "step": 12,
      "description":
          "What to do with the old/new SCOBY? You can either start a new batch or you can store it in the fridge. For that, reserve some kombutcha and place it in a glass container. Reserve enough so the SCOBY will be totally submerged in it. The cool temperature of the fridge will stop the fermentation, so you can use the SCOBY again whenever you please."
    }
  ];

  fetchReceipe() {
    _receipe = [];
    for (var json in _staticData) {
      _receipe?.add(ReceipeStep.fromJson(json));
    }
  }

  Future<List<ReceipeStep>> getReceipe() async {
    if (_receipe == null) {
      fetchReceipe();
    }
    return _receipe!;
  }
}
