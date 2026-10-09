import { useMutation, useQueryClient, type QueryKey } from '@tanstack/react-query';

/** useMutation that invalidates the given query areas on success. */
export function useApiMutation<TInput, TOutput>(
  fn: (input: TInput) => Promise<TOutput>,
  invalidate: readonly QueryKey[],
) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: async () => {
      await Promise.all(invalidate.map((queryKey) => queryClient.invalidateQueries({ queryKey })));
    },
  });
}
