import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The four fields a Saudi address is built from in the central catalogue: the
/// region and the city by their ids, the district, and the National Address
/// (J-14).
///
/// **It draws nothing at all unless there is something to offer.** The build has
/// to know how to ask for the catalogue (`AddressCatalogConfig`) and the store
/// has to have rows in it. A store whose catalogue has not been imported answers
/// an empty list, and then the form is the one this app has always had -- free
/// text, the shop-wide country and zip lists -- rather than two empty pickers
/// nobody can get past.
///
/// **The ids are the keys and the names never are.** A courier's coverage, a
/// warehouse and a marketplace are mapped to a city by its id, so what this
/// writes onto the address is `region_id` and `city_id`; the names are shown and
/// matched against nothing. The free-text city field above it is left alone, and
/// `zip` is never derived from the National Address.
///
/// The region and the city are required once they are offered, because an
/// address saved with one of them missing would pass this form and then fail
/// every coverage check afterwards with nothing on the screen to say why. The
/// district and the National Address are not: the platform's own `soft` mode
/// stores an address that has only part of this.
class AddressCatalogFieldsWidget extends StatefulWidget {
  /// The address being edited, so that the form opens on the region, the city,
  /// the district and the National Address it already holds. Null when a new
  /// address is being added.
  final AddressModel? existing;

  const AddressCatalogFieldsWidget({super.key, this.existing});

  @override
  State<AddressCatalogFieldsWidget> createState() => _AddressCatalogFieldsWidgetState();
}

class _AddressCatalogFieldsWidgetState extends State<AddressCatalogFieldsWidget> {
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _nationalAddressController = TextEditingController();
  final FocusNode _districtNode = FocusNode();
  final FocusNode _nationalAddressNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _districtController.text = widget.existing?.district ?? '';
    _nationalAddressController.text = widget.existing?.nationalAddress ?? '';

    // Read after the first frame, so that nothing notifies listeners while the tree is being
    // built, and the context is read HERE rather than inside the asynchronous part.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openOnTheCatalogue(Provider.of<AddressController>(context, listen: false));
      }
    });
  }

  /// Starts the form on what the address already holds: a clean choice, then the
  /// regions, then the region and the city of the address being edited.
  Future<void> _openOnTheCatalogue(AddressController addressController) async {
    // A fresh form, so that nothing a previous one chose is saved onto this address.
    addressController.forgetAddressCatalogChoice();
    await addressController.loadAddressRegions();
    await addressController.seedAddressCatalogChoice(widget.existing);
  }

  @override
  void dispose() {
    _districtController.dispose();
    _nationalAddressController.dispose();
    _districtNode.dispose();
    _nationalAddressNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressController>(
      builder: (BuildContext context, AddressController addressController, Widget? child) {
        if (!addressController.addressCatalogIsOffered) {
          return const SizedBox.shrink();
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _picker<AddressRegionModel>(
            context: context,
            label: getTranslated('address_region', context) ?? '',
            value: addressController.chosenRegion,
            rows: addressController.addressRegions,
            nameOf: (AddressRegionModel region) => region.name,
            keyOf: (AddressRegionModel region) => region.id,
            onChanged: addressController.chooseAddressRegion,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
          _picker<AddressCityModel>(
            context: context,
            label: getTranslated('address_city_from_catalog', context) ?? '',
            value: addressController.chosenCity,
            rows: addressController.addressCities,
            nameOf: (AddressCityModel city) => city.name,
            keyOf: (AddressCityModel city) => city.id,
            // Disabled rather than hidden until a region is chosen, so that the order of the two is
            // visible instead of a field appearing from nowhere.
            onChanged: addressController.chosenRegion == null ? null : addressController.chooseAddressCity,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
          CustomTextFieldWidget(
            labelText: getTranslated('address_district', context),
            hintText: getTranslated('address_district', context),
            inputType: TextInputType.streetAddress,
            inputAction: TextInputAction.next,
            focusNode: _districtNode,
            nextFocus: _nationalAddressNode,
            controller: _districtController,
            onChanged: addressController.writeAddressDistrict,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
          CustomTextFieldWidget(
            labelText: getTranslated('national_address', context),
            hintText: getTranslated('national_address_hint', context),
            inputType: TextInputType.text,
            inputAction: TextInputAction.next,
            focusNode: _nationalAddressNode,
            controller: _nationalAddressController,
            onChanged: addressController.writeNationalAddress,
          ),
        ]);
      },
    );
  }

  /// One picker of the catalogue. A row is named by [nameOf] and chosen by
  /// [keyOf], and the value is matched by that key rather than by identity, so
  /// a list read again does not lose what was already chosen.
  Widget _picker<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<T> rows,
    required String Function(T row) nameOf,
    required int Function(T row) keyOf,
    required void Function(T? row)? onChanged,
  }) {
    final int? held = value == null ? null : keyOf(value);
    // A list read again must not lose what is already chosen, and a chosen row that has gone
    // from the catalogue must not be handed to the dropdown, which throws on a value it has no
    // item for.
    final int? chosen = rows.any((T row) => keyOf(row) == held) ? held : null;

    return FormField<int>(
      initialValue: chosen,
      // Reads the CURRENT choice from the build above rather than the field's own value: the
      // choice lives in the controller, and this field exists only to join the form's validation
      // so that the save cannot pass with a region or a city missing.
      validator: (int? _) => chosen == null ? getTranslated('address_catalog_choice_required', context) : null,
      builder: (FormFieldState<int> field) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: field.errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
        ),
        child: DropdownButton<int>(
          value: chosen,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: rows
              .map((T row) => DropdownMenuItem<int>(
                    value: keyOf(row),
                    child: Text(nameOf(row), style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                  ))
              .toList(),
          onChanged: onChanged == null
              ? null
              : (int? picked) {
                  field.didChange(picked);
                  onChanged(picked == null ? null : rows.firstWhere((T row) => keyOf(row) == picked));
                },
        ),
      ),
    );
  }
}
