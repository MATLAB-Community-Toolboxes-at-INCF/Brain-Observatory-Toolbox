function cellsTable = listCells()
    dataset = bot.item.internal.enum.Dataset('VisualBehavior');
    manifest = bot.item.internal.Manifest.instance('Ophys', dataset);
    cellsTable = manifest.OphysCells;
end