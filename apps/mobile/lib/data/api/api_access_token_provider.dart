abstract interface class ApiAccessTokenProvider {
  Future<String?> getAccessToken();
}

class UnavailableApiAccessTokenProvider implements ApiAccessTokenProvider {
  const UnavailableApiAccessTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}
