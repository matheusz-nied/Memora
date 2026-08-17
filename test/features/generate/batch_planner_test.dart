import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/generate/batch_planner.dart';

void main() {
  group('computeBatchSizes', () {
    test('keeps a small request in a single batch', () {
      expect(computeBatchSizes(5), [5]);
      expect(computeBatchSizes(15), [15]);
    });

    test('balances the batches instead of leaving a tiny tail', () {
      expect(computeBatchSizes(25), [13, 12]);
      expect(computeBatchSizes(50), [13, 13, 12, 12]);
    });

    test('never exceeds the batch limit', () {
      for (final quantity in const [5, 10, 15, 25, 50]) {
        final sizes = computeBatchSizes(quantity);
        expect(sizes.every((size) => size <= 15), isTrue);
        expect(sizes.fold<int>(0, (total, size) => total + size), quantity);
      }
    });

    test('returns nothing for an empty request', () {
      expect(computeBatchSizes(0), isEmpty);
    });
  });

  group('chunkText', () {
    test('keeps short text in a single chunk', () {
      final chunks = chunkText('Um resumo curto de estudo.');

      expect(chunks, hasLength(1));
      expect(chunks.single, 'Um resumo curto de estudo.');
    });

    test('splits long text into chunks under the target size', () {
      final text = List.generate(
        400,
        (index) => 'Fato numero $index sobre o conteudo estudado.',
      ).join('\n\n');

      final chunks = chunkText(text, targetChars: 1000, minChars: 200);

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((chunk) => chunk.length <= 1000), isTrue);
    });

    test('breaks on paragraph boundaries', () {
      final paragraph = List.filled(60, 'palavra').join(' ');
      final chunks = chunkText(
        '$paragraph\n\n$paragraph',
        targetChars: 500,
        minChars: 100,
      );

      expect(chunks.first, paragraph);
    });

    test('merges a short tail into the previous chunk', () {
      final body = List.filled(300, 'palavra').join(' ');
      final chunks = chunkText(
        '$body\n\nfim.',
        targetChars: 700,
        minChars: 300,
      );

      expect(chunks.last, endsWith('fim.'));
      expect(chunks.every((chunk) => chunk.length >= 300), isTrue);
    });

    test('returns nothing for blank text', () {
      expect(chunkText('   '), isEmpty);
    });

    test('preserves the whole content across chunks', () {
      final text = List.generate(
        200,
        (index) => 'Frase $index com conteudo relevante.',
      ).join(' ');

      final chunks = chunkText(text, targetChars: 800, minChars: 200);

      expect(chunks.join(' ').replaceAll(RegExp(r'\s+'), ' '), text);
    });
  });

  group('chunkIndexForBatch', () {
    test('spreads batches across a long document', () {
      final indexes = List.generate(
        4,
        (batch) => chunkIndexForBatch(
          batchIndex: batch,
          batchCount: 4,
          chunkCount: 70,
        ),
      );

      expect(indexes, [0, 17, 35, 52]);
    });

    test('cycles through the chunks when there are fewer than batches', () {
      final indexes = List.generate(
        4,
        (batch) =>
            chunkIndexForBatch(batchIndex: batch, batchCount: 4, chunkCount: 2),
      );

      expect(indexes, [0, 1, 0, 1]);
    });

    test('always points at the single chunk of a short text', () {
      expect(
        chunkIndexForBatch(batchIndex: 3, batchCount: 4, chunkCount: 1),
        0,
      );
    });
  });
}
