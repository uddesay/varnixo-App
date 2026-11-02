import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/address_repository.dart';
import '../domain/address.dart';

final Provider<AddressRepository> addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(apiClientProvider)),
);

class AddressListState {
  const AddressListState({this.addresses = const [], this.isLoading = true, this.error});
  final List<Address> addresses;
  final bool isLoading;
  final Object? error;

  Address? get defaultAddress =>
      addresses.where((a) => a.isDefault).isEmpty ? null : addresses.firstWhere((a) => a.isDefault);

  AddressListState copyWith({List<Address>? addresses, bool? isLoading, Object? error}) =>
      AddressListState(
        addresses: addresses ?? this.addresses,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AddressController extends StateNotifier<AddressListState> {
  AddressController(this._repository) : super(const AddressListState()) {
    refresh();
  }

  final AddressRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final addresses = await _repository.list();
      state = state.copyWith(addresses: addresses, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<ApiException?> add(Address address) async {
    try {
      await _repository.create(address);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> update(String id, Address address) async {
    try {
      await _repository.update(id, address);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<void> setDefault(String id) async {
    await _repository.setDefault(id);
    await refresh();
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    await refresh();
  }
}

final StateNotifierProvider<AddressController, AddressListState> addressControllerProvider =
    StateNotifierProvider<AddressController, AddressListState>(
  (ref) => AddressController(ref.watch(addressRepositoryProvider)),
);
