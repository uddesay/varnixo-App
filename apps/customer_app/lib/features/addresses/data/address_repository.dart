import '../../../core/network/api_client.dart';
import '../domain/address.dart';

class AddressRepository {
  AddressRepository(this._client);

  final ApiClient _client;

  Future<List<Address>> list() async {
    final data = await _client.get('/addresses');
    return (data as List<dynamic>)
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Address> create(Address address) async {
    final data = await _client.post('/addresses', data: address.toJson());
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<Address> update(String id, Address address) async {
    final data = await _client.patch('/addresses/$id', data: address.toJson());
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> setDefault(String id) => _client.post('/addresses/$id/default');

  Future<void> remove(String id) => _client.delete('/addresses/$id');
}
