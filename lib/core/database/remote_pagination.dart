import 'package:supabase_flutter/supabase_flutter.dart';

/// Taille d'une page : alignée sur le plafond `max_rows` par défaut de
/// PostgREST, au-delà duquel le serveur tronque la réponse sans erreur.
const int remotePageSize = 1000;

/// Nombre d'identifiants par requête `inFilter` : au-delà, l'URL (≈ 37 octets
/// par UUID) dépasse la limite des proxys et le serveur répond 414.
const int remoteInFilterChunkSize = 200;

/// Rapatrie **toutes** les lignes d'une requête, page par page.
///
/// Un `.select()` nu est plafonné à ~1000 lignes : la purge locale qui suit
/// chaque pull aurait alors supprimé tout ce qui dépassait. [query] est
/// rappelée à chaque page, un builder PostgREST ne se réutilisant pas.
/// Le tri sur [orderBy] (colonne unique) garantit des pages sans trou ni
/// chevauchement.
Future<List<Map<String, dynamic>>> fetchAllPages(
  PostgrestFilterBuilder<PostgrestList> Function() query, {
  String orderBy = 'id',
}) async {
  final rows = <Map<String, dynamic>>[];
  var start = 0;
  while (true) {
    final page = await query()
        .order(orderBy, ascending: true)
        .range(start, start + remotePageSize - 1);
    rows.addAll(page);
    if (page.length < remotePageSize) break;
    start += remotePageSize;
  }
  return rows;
}

/// Variante de [fetchAllPages] pour un filtre `in` sur une longue liste
/// d'identifiants : découpe [ids] en lots, pagine chacun, et concatène.
Future<List<Map<String, dynamic>>> fetchAllPagesIn(
  PostgrestFilterBuilder<PostgrestList> Function() query, {
  required String column,
  required List<String> ids,
  String orderBy = 'id',
}) async {
  final rows = <Map<String, dynamic>>[];
  for (var i = 0; i < ids.length; i += remoteInFilterChunkSize) {
    final chunk = ids.sublist(
      i,
      i + remoteInFilterChunkSize > ids.length
          ? ids.length
          : i + remoteInFilterChunkSize,
    );
    rows.addAll(
      await fetchAllPages(
        () => query().inFilter(column, chunk),
        orderBy: orderBy,
      ),
    );
  }
  return rows;
}
