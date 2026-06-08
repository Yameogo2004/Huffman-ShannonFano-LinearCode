classdef Application < matlab.apps.AppBase

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % COMPOSANTS UI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        MainPanel               matlab.ui.container.Panel
        MenuPanel               matlab.ui.container.Panel
        DisplayPanel            matlab.ui.container.Panel
        ParamsPanel             matlab.ui.container.Panel

        TitleLabel              matlab.ui.control.Label
        FooterLabel             matlab.ui.control.Label

        OPENButton              matlab.ui.control.Button
        COMPRESSButton          matlab.ui.control.Button
        DECOMPRESSButton        matlab.ui.control.Button
        COMPAREButton           matlab.ui.control.Button
        SHOWHUFFTREEButton      matlab.ui.control.Button
        SHOWSFTREEButton        matlab.ui.control.Button
        LINEARCODEButton        matlab.ui.control.Button
        RESETButton             matlab.ui.control.Button
        EXITButton              matlab.ui.control.Button

        AlgorithmDropDownLabel  matlab.ui.control.Label
        AlgorithmDropDown       matlab.ui.control.DropDown

        ExtensionSpinnerLabel   matlab.ui.control.Label
        ExtensionSpinner        matlab.ui.control.Spinner

        UIAxesOriginal          matlab.ui.control.UIAxes
        UIAxesDecoded           matlab.ui.control.UIAxes

        SourceInfoTextArea      matlab.ui.control.TextArea
        ResultTextArea          matlab.ui.control.TextArea

        ComparisonTable         matlab.ui.control.Table

        OriginalSizeField       matlab.ui.control.EditField
        HuffmanSizeField        matlab.ui.control.EditField
        ShannonSizeField        matlab.ui.control.EditField
        HuffmanRatioField       matlab.ui.control.EditField
        ShannonRatioField       matlab.ui.control.EditField
        HuffmanEffField         matlab.ui.control.EditField
        ShannonEffField         matlab.ui.control.EditField
        HuffmanTimeField        matlab.ui.control.EditField
        ShannonTimeField        matlab.ui.control.EditField

        OriginalSizeLabel       matlab.ui.control.Label
        HuffmanSizeLabel        matlab.ui.control.Label
        ShannonSizeLabel        matlab.ui.control.Label
        HuffmanRatioLabel       matlab.ui.control.Label
        ShannonRatioLabel       matlab.ui.control.Label
        HuffmanEffLabel         matlab.ui.control.Label
        ShannonEffLabel         matlab.ui.control.Label
        HuffmanTimeLabel        matlab.ui.control.Label
        ShannonTimeLabel        matlab.ui.control.Label

        SourceInfoLabel         matlab.ui.control.Label
        ResultLabel             matlab.ui.control.Label
        CompareLabel            matlab.ui.control.Label
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DONNÉES DE L'APPLICATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = private)
        Data
        CurrentDataType
        ImageSize
        ImageClass

        ActiveAlgorithm

        HuffDict
        HuffCompressedData
        HuffPaddingSize = 0
        HuffExtensionN = 1

        SFDict
        SFCompressedData
        SFPaddingSize = 0
        SFExtensionN = 1

        LastDecodedData

        SourceSymbols
        SourceProbabilities
        SourceUniqueSymbols
        SourceExtensionN = 1
        SourcePaddingSize = 0

        HuffmanMetrics
        ShannonMetrics
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALLBACKS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function OPENButtonPushed(app, ~)
            [file, path] = uigetfile({'*.txt;*.jpg;*.jpeg;*.png', 'Fichiers texte ou image'});
            if isequal(file, 0)
                return;
            end

            fullpath = fullfile(path, file);
            [~, name, ext] = fileparts(fullpath);
            ext = lower(ext);

            app.resetInternalDataOnly();

            if strcmp(ext, '.txt')
                app.Data = fileread(fullpath);
                app.CurrentDataType = 'text';
                app.ImageSize = [];
                app.ImageClass = [];

                cla(app.UIAxesOriginal);
                cla(app.UIAxesDecoded);
                title(app.UIAxesOriginal, 'Original');
                title(app.UIAxesDecoded, 'Décodé');

                app.SourceInfoTextArea.Value = {
                    ['Nom du fichier : ' name ext]
                    'Type : Texte'
                    ['Nombre de caractères : ' num2str(length(app.Data))]
                    'Statut : texte chargé avec succès'
                };

            elseif ismember(ext, {'.jpg', '.jpeg', '.png'})
                app.Data = imread(fullpath);
                app.CurrentDataType = 'image';
                app.ImageSize = size(app.Data);
                app.ImageClass = class(app.Data);

                imshow(app.Data, 'Parent', app.UIAxesOriginal);
                title(app.UIAxesOriginal, 'Image originale');
                cla(app.UIAxesDecoded);
                title(app.UIAxesDecoded, 'Image décodée');

                dims = size(app.Data);
                if numel(dims) == 2
                    dimText = [num2str(dims(1)) ' x ' num2str(dims(2))];
                else
                    dimText = [num2str(dims(1)) ' x ' num2str(dims(2)) ' x ' num2str(dims(3))];
                end

                app.SourceInfoTextArea.Value = {
                    ['Nom du fichier : ' name ext]
                    'Type : Image'
                    ['Dimensions : ' dimText]
                    ['Classe : ' class(app.Data)]
                    'Statut : image chargée avec succès'
                };
            else
                app.SourceInfoTextArea.Value = {'Format de fichier non pris en charge'};
                return;
            end

            app.ResultTextArea.Value = {'Prêt pour la compression'};
            app.ComparisonTable.Data = cell(0,8);
        end

        function COMPRESSButtonPushed(app, ~)
            if isempty(app.Data)
                app.ResultTextArea.Value = {'Veuillez d''abord charger un texte ou une image'};
                return;
            end

            selectedAlgo = app.AlgorithmDropDown.Value;
            app.ActiveAlgorithm = selectedAlgo;

            app.prepareSource();

            switch selectedAlgo
                case 'Huffman'
                    app.compressHuffmanOnly();
                case 'Shannon-Fano'
                    app.compressShannonOnly();
            end
        end

        function DECOMPRESSButtonPushed(app, ~)
            if isempty(app.Data)
                app.ResultTextArea.Value = {'Veuillez d''abord charger une source'};
                return;
            end

            selectedAlgo = app.AlgorithmDropDown.Value;

            switch selectedAlgo
                case 'Huffman'
                    if isempty(app.HuffCompressedData) || isempty(app.HuffDict)
                        app.ResultTextArea.Value = {'Veuillez d''abord compresser avec Huffman'};
                        return;
                    end
                    decoded = app.decodeWithHuffman();

                case 'Shannon-Fano'
                    if isempty(app.SFCompressedData) || isempty(app.SFDict)
                        app.ResultTextArea.Value = {'Veuillez d''abord compresser avec Shannon-Fano'};
                        return;
                    end
                    decoded = app.decodeWithShannon();
            end

            app.LastDecodedData = decoded;
            app.displayDecodedData(decoded, selectedAlgo);
        end

        function COMPAREButtonPushed(app, ~)
            if isempty(app.Data)
                app.ResultTextArea.Value = {'Veuillez d''abord charger une source'};
                return;
            end

            app.prepareSource();
            app.computeHuffmanMetrics();
            app.computeShannonMetrics();
            app.updateMetricsFields();
            app.showComparisonText();
        end

        function SHOWHUFFTREEButtonPushed(app, ~)
            if isempty(app.HuffDict)
                if isempty(app.Data)
                    app.ResultTextArea.Value = {'Chargez d''abord une source'};
                    return;
                end
                app.prepareSource();
                app.computeHuffmanMetrics();
                app.updateMetricsFields();
            end
            app.showCodeTree(app.HuffDict, 'Arbre de Huffman');
        end

        function SHOWSFTREEButtonPushed(app, ~)
            if isempty(app.SFDict)
                if isempty(app.Data)
                    app.ResultTextArea.Value = {'Chargez d''abord une source'};
                    return;
                end
                app.prepareSource();
                app.computeShannonMetrics();
                app.updateMetricsFields();
            end
            app.showCodeTree(app.SFDict, 'Arbre de Shannon-Fano');
        end

        function LINEARCODEButtonPushed(app, ~)
            app.openLinearCodeDashboard();
        end

        function RESETButtonPushed(app, ~)
            app.resetAll();
        end

        function EXITButtonPushed(app, ~)
            delete(app);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MÉTHODES PRINCIPALES - CODAGE DE SOURCE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function prepareSource(app)
            if strcmp(app.CurrentDataType, 'text')
                N = max(1, round(app.ExtensionSpinner.Value));
                txt = app.Data;
                app.SourceExtensionN = N;

                if isempty(txt)
                    app.SourceSymbols = {};
                    app.SourceUniqueSymbols = {};
                    app.SourceProbabilities = [];
                    app.SourcePaddingSize = 0;
                    return;
                end

                if N == 1
                    app.SourcePaddingSize = 0;
                    app.SourceSymbols = cellstr(num2cell(txt(:)));
                else
                    L = length(txt);
                    pad = mod(N - mod(L, N), N);
                    if pad == N
                        pad = 0;
                    end
                    app.SourcePaddingSize = pad;
                    txtPadded = [txt repmat(' ', 1, pad)];

                    numBlocks = length(txtPadded) / N;
                    blocks = cell(numBlocks,1);

                    for i = 1:numBlocks
                        startIndex = (i-1)*N + 1;
                        blocks{i} = txtPadded(startIndex:startIndex+N-1);
                    end
                    app.SourceSymbols = blocks;
                end

                [app.SourceUniqueSymbols, ~, idx] = unique(app.SourceSymbols);
                counts = accumarray(idx, 1);
                app.SourceProbabilities = counts / sum(counts);
                app.SourceProbabilities = app.SourceProbabilities(:);

            else
                imgVec = double(app.Data(:));
                symbolsCell = num2cell(imgVec);

                app.SourceSymbols = symbolsCell;
                app.SourceExtensionN = 1;
                app.SourcePaddingSize = 0;

                [uniqueVals, ~, idx] = unique(imgVec);
                counts = accumarray(idx, 1);
                app.SourceProbabilities = counts / sum(counts);
                app.SourceProbabilities = app.SourceProbabilities(:);
                app.SourceUniqueSymbols = num2cell(uniqueVals);
            end
        end

        function compressHuffmanOnly(app)
            app.computeHuffmanMetrics();
            app.updateMetricsFields();

            M = app.HuffmanMetrics;
            app.ResultTextArea.Value = {
                'Compression terminée avec : Huffman'
                ['Ordre d''extension N : ' num2str(M.extensionN)]
                ' '
                ['Entropie initiale H(X) : ' num2str(M.entropyInitial)]
                ['Entropie par bloc H(N) : ' num2str(M.entropyBlock)]
                ['Entropie par symbole : ' num2str(M.entropyPerSymbol)]
                ' '
                ['Longueur moyenne par bloc : ' num2str(M.avgLength)]
                ['Longueur moyenne par symbole : ' num2str(M.avgLengthPerSymbol)]
                ' '
                ['Taille compressée (bits) : ' num2str(M.compressedSize)]
                ['Taux de compression : ' num2str(M.ratio)]
                ['Efficacité (%) : ' num2str(M.efficiency)]
                ['Temps (s) : ' num2str(M.time)]
            };
        end

        function compressShannonOnly(app)
            app.computeShannonMetrics();
            app.updateMetricsFields();

            M = app.ShannonMetrics;
            app.ResultTextArea.Value = {
                'Compression terminée avec : Shannon-Fano'
                ['Ordre d''extension N : ' num2str(M.extensionN)]
                ' '
                ['Entropie initiale H(X) : ' num2str(M.entropyInitial)]
                ['Entropie par bloc H(N) : ' num2str(M.entropyBlock)]
                ['Entropie par symbole : ' num2str(M.entropyPerSymbol)]
                ' '
                ['Longueur moyenne par bloc : ' num2str(M.avgLength)]
                ['Longueur moyenne par symbole : ' num2str(M.avgLengthPerSymbol)]
                ' '
                ['Taille compressée (bits) : ' num2str(M.compressedSize)]
                ['Taux de compression : ' num2str(M.ratio)]
                ['Efficacité (%) : ' num2str(M.efficiency)]
                ['Temps (s) : ' num2str(M.time)]
            };
        end

        function computeHuffmanMetrics(app)
            tic;

            prob = app.SourceProbabilities;
            uniqueSymbols = app.SourceUniqueSymbols;
            rawSymbols = app.SourceSymbols;
            N = app.SourceExtensionN;

            dict = huffmandict(uniqueSymbols, prob);
            dict = app.normalizeEmptyCodes(dict);

            encoded = huffmanenco(rawSymbols, dict);
            t = toc;

            originalSize = app.getOriginalSizeBits();
            compressedSize = length(encoded);

            if compressedSize ~= 0
                ratio = originalSize / compressedSize;
            else
                ratio = 0;
            end

            probNZ = prob(prob > 0);
            entropyBlock = -sum(probNZ .* log2(probNZ));
            entropyInitial = app.computeInitialEntropy();

            if ~isempty(rawSymbols)
                avgLength = compressedSize / length(rawSymbols);
            else
                avgLength = 0;
            end

            entropyPerSymbol = entropyBlock / N;
            avgLengthPerSymbol = avgLength / N;

            if avgLength ~= 0
                efficiency = (entropyBlock / avgLength) * 100;
            else
                efficiency = 0;
            end

            app.HuffDict = dict;
            app.HuffCompressedData = encoded;
            app.HuffPaddingSize = app.SourcePaddingSize;
            app.HuffExtensionN = N;

            app.HuffmanMetrics = struct( ...
                'originalSize', originalSize, ...
                'compressedSize', compressedSize, ...
                'ratio', ratio, ...
                'entropyInitial', entropyInitial, ...
                'entropyBlock', entropyBlock, ...
                'entropyPerSymbol', entropyPerSymbol, ...
                'avgLength', avgLength, ...
                'avgLengthPerSymbol', avgLengthPerSymbol, ...
                'efficiency', efficiency, ...
                'time', t, ...
                'extensionN', N);
        end

        function computeShannonMetrics(app)
            tic;

            prob = app.SourceProbabilities;
            uniqueSymbols = app.SourceUniqueSymbols;
            rawSymbols = app.SourceSymbols;
            N = app.SourceExtensionN;

            dict = app.buildShannonFanoDict(uniqueSymbols, prob);
            dict = app.normalizeEmptyCodes(dict);

            encoded = app.sfEncode(rawSymbols, dict);
            t = toc;

            originalSize = app.getOriginalSizeBits();
            compressedSize = length(encoded);

            if compressedSize ~= 0
                ratio = originalSize / compressedSize;
            else
                ratio = 0;
            end

            probNZ = prob(prob > 0);
            entropyBlock = -sum(probNZ .* log2(probNZ));
            entropyInitial = app.computeInitialEntropy();

            if ~isempty(rawSymbols)
                avgLength = compressedSize / length(rawSymbols);
            else
                avgLength = 0;
            end

            entropyPerSymbol = entropyBlock / N;
            avgLengthPerSymbol = avgLength / N;

            if avgLength ~= 0
                efficiency = (entropyBlock / avgLength) * 100;
            else
                efficiency = 0;
            end

            app.SFDict = dict;
            app.SFCompressedData = encoded;
            app.SFPaddingSize = app.SourcePaddingSize;
            app.SFExtensionN = N;

            app.ShannonMetrics = struct( ...
                'originalSize', originalSize, ...
                'compressedSize', compressedSize, ...
                'ratio', ratio, ...
                'entropyInitial', entropyInitial, ...
                'entropyBlock', entropyBlock, ...
                'entropyPerSymbol', entropyPerSymbol, ...
                'avgLength', avgLength, ...
                'avgLengthPerSymbol', avgLengthPerSymbol, ...
                'efficiency', efficiency, ...
                'time', t, ...
                'extensionN', N);
        end

        function decoded = decodeWithHuffman(app)
            decodedSymbols = huffmandeco(app.HuffCompressedData, app.HuffDict);
            decoded = app.rebuildDecodedData(decodedSymbols, app.HuffPaddingSize, app.HuffExtensionN);
        end

        function decoded = decodeWithShannon(app)
            decodedSymbols = app.sfDecode(app.SFCompressedData, app.SFDict);
            decoded = app.rebuildDecodedData(decodedSymbols, app.SFPaddingSize, app.SFExtensionN);
        end

        function decoded = rebuildDecodedData(app, decodedSymbols, paddingSize, extensionN)
            if strcmp(app.CurrentDataType, 'text')
                if extensionN == 1
                    if iscell(decodedSymbols)
                        decoded = char(strjoin(decodedSymbols, ''));
                    else
                        decoded = char(decodedSymbols);
                    end
                else
                    if iscell(decodedSymbols)
                        decoded = [decodedSymbols{:}];
                    else
                        decoded = char(decodedSymbols);
                    end
                    if paddingSize > 0 && length(decoded) >= paddingSize
                        decoded = decoded(1:end-paddingSize);
                    end
                end
            else
                if iscell(decodedSymbols)
                    vec = cell2mat(decodedSymbols);
                else
                    vec = decodedSymbols;
                end

                if strcmp(app.ImageClass, 'uint8')
                    vec = uint8(vec);
                elseif strcmp(app.ImageClass, 'uint16')
                    vec = uint16(vec);
                else
                    vec = cast(vec, app.ImageClass);
                end

                decoded = reshape(vec, app.ImageSize);
            end
        end

        function displayDecodedData(app, decoded, algoName)
            if strcmp(app.CurrentDataType, 'text')
                cla(app.UIAxesDecoded);
                title(app.UIAxesDecoded, 'Décodé');

                if strcmp(app.Data, decoded)
                    app.ResultTextArea.Value = {
                        ['Décompression réussie avec ' algoName]
                        ' '
                        'Texte décodé :'
                        decoded
                    };
                else
                    app.ResultTextArea.Value = {
                        ['Erreur de décompression avec ' algoName]
                        ' '
                        'Texte décodé :'
                        decoded
                    };
                end

            else
                imshow(decoded, 'Parent', app.UIAxesDecoded);
                title(app.UIAxesDecoded, ['Image décodée - ' algoName]);

                if isequal(app.Data, decoded)
                    app.ResultTextArea.Value = {['Image décompressée correctement avec ' algoName]};
                else
                    app.ResultTextArea.Value = {['L''image décodée est différente de l''originale avec ' algoName]};
                end
            end
        end

        function updateMetricsFields(app)
            if isempty(app.Data)
                return;
            end

            originalBits = app.getOriginalSizeBits();
            app.OriginalSizeField.Value = num2str(originalBits);

            if ~isempty(app.HuffmanMetrics)
                app.HuffmanSizeField.Value = num2str(app.HuffmanMetrics.compressedSize);
                app.HuffmanRatioField.Value = num2str(app.HuffmanMetrics.ratio);
                app.HuffmanEffField.Value = num2str(app.HuffmanMetrics.efficiency);
                app.HuffmanTimeField.Value = num2str(app.HuffmanMetrics.time);
            else
                app.HuffmanSizeField.Value = '';
                app.HuffmanRatioField.Value = '';
                app.HuffmanEffField.Value = '';
                app.HuffmanTimeField.Value = '';
            end

            if ~isempty(app.ShannonMetrics)
                app.ShannonSizeField.Value = num2str(app.ShannonMetrics.compressedSize);
                app.ShannonRatioField.Value = num2str(app.ShannonMetrics.ratio);
                app.ShannonEffField.Value = num2str(app.ShannonMetrics.efficiency);
                app.ShannonTimeField.Value = num2str(app.ShannonMetrics.time);
            else
                app.ShannonSizeField.Value = '';
                app.ShannonRatioField.Value = '';
                app.ShannonEffField.Value = '';
                app.ShannonTimeField.Value = '';
            end
        end

        function showComparisonText(app)
            if isempty(app.HuffmanMetrics) || isempty(app.ShannonMetrics)
                app.ComparisonTable.Data = cell(0,8);
                return;
            end

            H = app.HuffmanMetrics;
            S = app.ShannonMetrics;

            app.ComparisonTable.Data = {
                'Huffman', H.compressedSize, H.ratio, H.entropyBlock, H.entropyPerSymbol, H.avgLengthPerSymbol, H.efficiency, H.time;
                'Shannon-Fano', S.compressedSize, S.ratio, S.entropyBlock, S.entropyPerSymbol, S.avgLengthPerSymbol, S.efficiency, S.time
            };
        end

        function bits = getOriginalSizeBits(app)
            bits = numel(app.Data) * 8;
        end

        function entropyInitial = computeInitialEntropy(app)
            if isempty(app.Data)
                entropyInitial = 0;
                return;
            end

            if strcmp(app.CurrentDataType, 'text')
                chars = cellstr(num2cell(app.Data(:)));
                [~, ~, idx] = unique(chars);
                counts = accumarray(idx, 1);
                p = counts / sum(counts);
            else
                imgVec = double(app.Data(:));
                [~, ~, idx] = unique(imgVec);
                counts = accumarray(idx, 1);
                p = counts / sum(counts);
            end

            p = p(:);
            p = p(p > 0);
            entropyInitial = -sum(p .* log2(p));
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % SHANNON-FANO
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function dict = buildShannonFanoDict(app, symbols, prob)
            prob = prob(:);
            n = length(prob);

            temp = cell(n, 3);
            for i = 1:n
                temp{i,1} = symbols{i};
                temp{i,2} = prob(i);
                temp{i,3} = [];
            end

            probArray = cell2mat(temp(:,2));
            [~, order] = sort(probArray, 'descend');
            temp = temp(order, :);

            temp = app.sfAssignCodes(temp, 1, size(temp,1));

            dict = cell(size(temp,1), 2);
            dict(:,1) = temp(:,1);
            dict(:,2) = temp(:,3);
        end

        function tableData = sfAssignCodes(app, tableData, leftIdx, rightIdx)
            if leftIdx >= rightIdx
                return;
            end

            total = sum(cell2mat(tableData(leftIdx:rightIdx, 2)));
            bestSplit = leftIdx;
            bestDiff = inf;
            cum = 0;

            for k = leftIdx:rightIdx-1
                cum = cum + tableData{k,2};
                diffVal = abs(total - 2*cum);
                if diffVal < bestDiff
                    bestDiff = diffVal;
                    bestSplit = k;
                end
            end

            for i = leftIdx:bestSplit
                tableData{i,3} = [tableData{i,3} 0];
            end
            for i = bestSplit+1:rightIdx
                tableData{i,3} = [tableData{i,3} 1];
            end

            tableData = app.sfAssignCodes(tableData, leftIdx, bestSplit);
            tableData = app.sfAssignCodes(tableData, bestSplit+1, rightIdx);
        end

        function encoded = sfEncode(app, rawSymbols, dict)
            map = containers.Map('KeyType','char','ValueType','any');
            for i = 1:size(dict,1)
                key = app.symbolToKey(dict{i,1});
                map(key) = dict{i,2};
            end

            encoded = [];
            for i = 1:length(rawSymbols)
                key = app.symbolToKey(rawSymbols{i});
                encoded = [encoded map(key)]; %#ok<AGROW>
            end
        end

        function decodedSymbols = sfDecode(app, bitstream, dict)
            reverseMap = containers.Map('KeyType','char','ValueType','any');
            for i = 1:size(dict,1)
                codeStr = app.bitsToString(dict{i,2});
                reverseMap(codeStr) = dict{i,1};
            end

            decodedSymbols = {};
            currentBits = '';
            for i = 1:length(bitstream)
                currentBits = [currentBits num2str(bitstream(i))]; %#ok<AGROW>
                if isKey(reverseMap, currentBits)
                    decodedSymbols{end+1,1} = reverseMap(currentBits); %#ok<AGROW>
                    currentBits = '';
                end
            end
            decodedSymbols = decodedSymbols(:);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % UTILITAIRES
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function key = symbolToKey(app, symbol)
            if ischar(symbol)
                if isempty(symbol)
                    key = '<EMPTY>';
                else
                    key = ['C_' double2str(double(symbol))];
                end
            elseif isnumeric(symbol)
                key = ['N_' num2str(symbol)];
            else
                key = ['X_' char(string(symbol))];
            end
        end

        function str = bitsToString(app, bits)
            if isempty(bits)
                str = '0';
                return;
            end
            str = sprintf('%d', bits);
        end

        function str = prettyBits(app, bits)
            if isempty(bits)
                str = '0';
                return;
            end

            raw = sprintf('%d', bits);
            n = length(raw);
            parts = {};
            idx = 1;
            while idx <= n
                idx2 = min(idx + 3, n);
                parts{end+1} = raw(idx:idx2); %#ok<AGROW>
                idx = idx2 + 1;
            end

            str = strjoin(parts, ' ');
        end

        function dict = normalizeEmptyCodes(app, dict)
            for i = 1:size(dict,1)
                if isempty(dict{i,2})
                    dict{i,2} = 0;
                end
            end
        end

        function text = symbolToDisplay(app, sym)
            if ischar(sym)
                if isequal(sym, ' ')
                    text = 'espace';
                elseif isequal(sym, sprintf('\n'))
                    text = '\n';
                elseif isequal(sym, sprintf('\r'))
                    text = '\r';
                elseif isequal(sym, sprintf('\t'))
                    text = '\t';
                elseif length(sym) > 1
                    text = sym;
                else
                    text = sym;
                end
            elseif isnumeric(sym)
                text = num2str(sym);
            else
                text = char(string(sym));
            end
        end

        function text = shortSymbolLabel(app, sym)
            text = app.symbolToDisplay(sym);
            if length(text) > 12
                text = [text(1:12) '...'];
            end
        end

        function showCodeTree(app, dict, figTitle)
            if isempty(dict)
                return;
            end

            nodeNames  = {'Racine'};
            nodeLabels = {'Racine'};
            sources = {};
            targets = {};
            edgeTypes = [];

            nodeMap = containers.Map('KeyType','char','ValueType','int32');
            nodeMap('') = int32(1);

            leafNodeIdx = [];
            internalNodeIdx = 1;

            for i = 1:size(dict,1)
                sym = dict{i,1};
                bits = dict{i,2};
                if isempty(bits)
                    bits = 0;
                end

                currentPath = '';
                parentName = 'Racine';

                for j = 1:length(bits)
                    bitVal = bits(j);
                    currentPath = [currentPath num2str(bitVal)]; %#ok<AGROW>
                    nodeName = ['N_' currentPath];

                    if ~isKey(nodeMap, currentPath)
                        nodeNames{end+1} = nodeName; %#ok<AGROW>
                        nodeLabels{end+1} = ['Bit ' num2str(bitVal)]; %#ok<AGROW>
                        nodeMap(currentPath) = int32(numel(nodeNames));
                        internalNodeIdx(end+1) = numel(nodeNames); %#ok<AGROW>

                        sources{end+1} = parentName; %#ok<AGROW>
                        targets{end+1} = nodeName; %#ok<AGROW>
                        edgeTypes(end+1) = bitVal; %#ok<AGROW>
                    end

                    parentName = nodeName;
                end

                leafName = ['L_' num2str(i)];
                symText = app.shortSymbolLabel(sym);
                codeText = app.prettyBits(bits);
                leafLabel = [symText '  |  ' codeText];

                nodeNames{end+1} = leafName; %#ok<AGROW>
                nodeLabels{end+1} = leafLabel; %#ok<AGROW>
                leafNodeIdx(end+1) = numel(nodeNames); %#ok<AGROW>

                sources{end+1} = parentName; %#ok<AGROW>
                targets{end+1} = leafName; %#ok<AGROW>
                edgeTypes(end+1) = 2; %#ok<AGROW>
            end

            G = digraph(sources, targets, [], nodeNames);

            fig = figure('Name', figTitle, 'NumberTitle', 'off', 'Color', 'w', ...
                'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

            ax = axes('Parent', fig, 'Position', [0.02 0.06 0.96 0.90]);

            p = plot(ax, G, ...
                'Layout', 'layered', ...
                'Direction', 'right', ...
                'NodeLabel', nodeLabels, ...
                'Interpreter', 'none');

            p.Marker = 'o';
            p.MarkerSize = 4;
            p.LineWidth = 1.1;
            p.ArrowSize = 10;
            p.NodeFontSize = 8;
            p.NodeColor = [0.20 0.35 0.75];
            p.EdgeColor = [0.55 0.55 0.55];

            try
                highlight(p, 1, 'NodeColor', [0.85 0.20 0.12], 'MarkerSize', 8);
            catch
            end

            if numel(internalNodeIdx) > 1
                try
                    highlight(p, internalNodeIdx, 'NodeColor', [0.20 0.35 0.75], 'MarkerSize', 4);
                catch
                end
            end

            if ~isempty(leafNodeIdx)
                try
                    highlight(p, leafNodeIdx, 'NodeColor', [0.10 0.60 0.25], 'MarkerSize', 5);
                catch
                end
            end

            idx0 = find(edgeTypes == 0);
            idx1 = find(edgeTypes == 1);
            idxLeaf = find(edgeTypes == 2);

            try
                if ~isempty(idx0)
                    highlight(p, 'Edges', idx0, 'EdgeColor', [0.15 0.45 0.90], 'LineWidth', 1.6);
                end
                if ~isempty(idx1)
                    highlight(p, 'Edges', idx1, 'EdgeColor', [0.90 0.35 0.20], 'LineWidth', 1.6);
                end
                if ~isempty(idxLeaf)
                    highlight(p, 'Edges', idxLeaf, 'EdgeColor', [0.45 0.45 0.45], 'LineStyle', '-', 'LineWidth', 1.0);
                end
            catch
            end

            title(ax, figTitle, 'FontWeight', 'bold', 'FontSize', 16);
            axis(ax, 'tight');
            axis(ax, 'off');
        end

        function resetInternalDataOnly(app)
            app.HuffDict = [];
            app.HuffCompressedData = [];
            app.HuffPaddingSize = 0;
            app.HuffExtensionN = 1;

            app.SFDict = [];
            app.SFCompressedData = [];
            app.SFPaddingSize = 0;
            app.SFExtensionN = 1;

            app.LastDecodedData = [];
            app.SourceSymbols = [];
            app.SourceProbabilities = [];
            app.SourceUniqueSymbols = [];
            app.SourceExtensionN = 1;
            app.SourcePaddingSize = 0;

            app.HuffmanMetrics = [];
            app.ShannonMetrics = [];
            app.ActiveAlgorithm = [];
        end

        function resetAll(app)
            app.Data = [];
            app.CurrentDataType = [];
            app.ImageSize = [];
            app.ImageClass = [];

            app.resetInternalDataOnly();

            app.SourceInfoTextArea.Value = {''};
            app.ResultTextArea.Value = {''};
            app.ComparisonTable.Data = cell(0,8);

            app.OriginalSizeField.Value = '';
            app.HuffmanSizeField.Value = '';
            app.ShannonSizeField.Value = '';
            app.HuffmanRatioField.Value = '';
            app.ShannonRatioField.Value = '';
            app.HuffmanEffField.Value = '';
            app.ShannonEffField.Value = '';
            app.HuffmanTimeField.Value = '';
            app.ShannonTimeField.Value = '';

            app.ExtensionSpinner.Value = 1;

            cla(app.UIAxesOriginal);
            cla(app.UIAxesDecoded);
            title(app.UIAxesOriginal, 'Original');
            title(app.UIAxesDecoded, 'Décodé');
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TABLEAU DE BORD CODE LINÉAIRE C(7,3)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function openLinearCodeDashboard(app)

            bgFigure   = [0.95 0.97 0.99];
            bgLeft     = [0.96 0.92 0.86];
            bgRight    = [0.99 0.98 0.95];
            gold       = [0.92 0.69 0.14];
            blueAccent = [0.10 0.40 0.75];
            grayBtn    = [0.85 0.88 0.92];

            f = uifigure( ...
                'Name', 'Tableau de bord - Code linéaire binaire C(7,3)', ...
                'Color', bgFigure, ...
                'Position', [60 40 1500 860], ...
                'AutoResizeChildren', 'off');

            uilabel(f, ...
                'Text', 'ANALYSE D''UN CODE LINÉAIRE BINAIRE C(7,3)', ...
                'FontSize', 24, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'FontColor', [0.78 0.30 0.10], ...
                'Position', [300 810 900 30]);

            leftPanel = uipanel(f, ...
                'Title', 'ENTRÉES / ACTIONS', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', bgLeft, ...
                'Position', [20 20 340 780]);

            rightPanel = uipanel(f, ...
                'Title', 'RÉSULTATS', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', bgRight, ...
                'Position', [375 20 1105 780]);

            uilabel(leftPanel, ...
                'Text', 'Matrice génératrice G (3x7)', ...
                'FontWeight', 'bold', ...
                'Position', [20 705 280 22]);

            defaultG = sprintf([ ...
                '1 0 0 0 1 1 0\n' ...
                '0 1 0 1 0 1 1\n' ...
                '0 0 1 1 1 0 1']);

            GArea = uitextarea(leftPanel, ...
                'Position', [20 580 295 120], ...
                'Value', splitlines(string(defaultG)), ...
                'FontName', 'Courier New', ...
                'FontSize', 15);

            uilabel(leftPanel, ...
                'Text', 'Message m (1x3) à coder', ...
                'FontWeight', 'bold', ...
                'Position', [20 540 250 22]);

            MsgField = uieditfield(leftPanel, 'text', ...
                'Position', [20 510 295 30], ...
                'Value', '1 0 0', ...
                'FontSize', 14);

            uilabel(leftPanel, ...
                'Text', 'Position de l''erreur k (1 à 7)', ...
                'FontWeight', 'bold', ...
                'Position', [20 470 250 22]);

            ErrPosSpinner = uispinner(leftPanel, ...
                'Position', [20 440 90 28], ...
                'Limits', [1 7], ...
                'Step', 1, ...
                'Value', 1);

            uibutton(leftPanel, 'push', ...
                'Text', 'GÉNÉRER / ANALYSER', ...
                'Position', [20 370 295 42], ...
                'BackgroundColor', gold, ...
                'FontWeight', 'bold', ...
                'FontSize', 14, ...
                'ButtonPushedFcn', @onGenerateAnalyze);

            uibutton(leftPanel, 'push', ...
                'Text', 'SIMULER UNE ERREUR', ...
                'Position', [20 315 295 42], ...
                'BackgroundColor', gold, ...
                'FontWeight', 'bold', ...
                'FontSize', 14, ...
                'ButtonPushedFcn', @onSimulateError);

            uibutton(leftPanel, 'push', ...
                'Text', 'DÉCODAGE / CORRECTION', ...
                'Position', [20 260 295 42], ...
                'BackgroundColor', gold, ...
                'FontWeight', 'bold', ...
                'FontSize', 14, ...
                'ButtonPushedFcn', @onDecodeCorrect);

            uibutton(leftPanel, 'push', ...
                'Text', 'EFFACER', ...
                'Position', [20 205 295 42], ...
                'BackgroundColor', grayBtn, ...
                'FontWeight', 'bold', ...
                'FontSize', 14, ...
                'ButtonPushedFcn', @onClear);

            HelpLbl = uitextarea(leftPanel, ...
                'Position', [20 25 295 160], ...
                'Editable', 'off', ...
                'FontSize', 14);

            HelpLbl.Value = {
                'Étapes :'
                '1) Entrer la matrice G (3x7)'
                '2) Cliquer sur "GÉNÉRER / ANALYSER"'
                '3) Choisir le message m'
                '4) Choisir la position de l''erreur'
                '5) Cliquer sur "SIMULER UNE ERREUR"'
                '6) Cliquer sur "DÉCODAGE / CORRECTION"'
            };

            uilabel(rightPanel, ...
                'Text', 'Table des messages, mots-code et poids', ...
                'FontWeight', 'bold', ...
                'FontSize', 15, ...
                'FontColor', blueAccent, ...
                'Position', [20 720 380 24]);

            CodewordsTable = uitable(rightPanel, ...
                'Position', [20 455 1055 250], ...
                'ColumnName', {'m1','m2','m3','c1','c2','c3','c4','c5','c6','c7','Poids'}, ...
                'RowName', {}, ...
                'ColumnEditable', false(1,11), ...
                'FontSize', 13);
            CodewordsTable.ColumnWidth = {60,60,60,60,60,60,60,60,60,60,80};

            uilabel(rightPanel, ...
                'Text', 'Matrice G', ...
                'FontWeight', 'bold', ...
                'FontSize', 15, ...
                'FontColor', blueAccent, ...
                'Position', [20 410 120 24]);

            MatrixTableG = uitable(rightPanel, ...
                'Position', [20 240 500 150], ...
                'ColumnName', {'1','2','3','4','5','6','7'}, ...
                'RowName', {'L1','L2','L3'}, ...
                'ColumnEditable', false(1,7), ...
                'FontSize', 14);
            MatrixTableG.ColumnWidth = {55,55,55,55,55,55,55};

            uilabel(rightPanel, ...
                'Text', 'Matrice de contrôle H', ...
                'FontWeight', 'bold', ...
                'FontSize', 15, ...
                'FontColor', blueAccent, ...
                'Position', [560 410 220 24]);

            MatrixTableH = uitable(rightPanel, ...
                'Position', [560 210 515 180], ...
                'ColumnName', {'1','2','3','4','5','6','7'}, ...
                'RowName', {'L1','L2','L3','L4'}, ...
                'ColumnEditable', false(1,7), ...
                'FontSize', 14);
            MatrixTableH.ColumnWidth = {55,55,55,55,55,55,55};

            uilabel(rightPanel, ...
                'Text', 'Résumé', ...
                'FontWeight', 'bold', ...
                'FontSize', 15, ...
                'FontColor', blueAccent, ...
                'Position', [20 165 120 24]);

            SummaryArea = uitextarea(rightPanel, ...
                'Position', [20 85 1055 80], ...
                'Editable', 'off', ...
                'FontSize', 14);
            SummaryArea.Value = {'Les résultats apparaîtront ici...'};

            uilabel(rightPanel, ...
                'Text', 'Détails des étapes', ...
                'FontWeight', 'bold', ...
                'FontSize', 15, ...
                'FontColor', blueAccent, ...
                'Position', [20 50 200 24]);

            StepsArea = uitextarea(rightPanel, ...
                'Position', [20 15 1055 40], ...
                'Editable', 'off', ...
                'FontSize', 14);
            StepsArea.Value = {'Les étapes détaillées apparaîtront ici...'};

            state = struct();
            state.G = [];
            state.H = [];
            state.codewords = [];
            state.messages = [];
            state.lastCodeword = [];
            state.lastReceived = [];
            state.lastCorrected = [];

            function onGenerateAnalyze(~, ~)
                try
                    G = app.parseBinaryMatrix(GArea.Value, 3, 7);
                    [k, n] = size(G);

                    if ~(k == 3 && n == 7)
                        uialert(f, 'La matrice G doit être de taille 3x7.', 'Matrice invalide');
                        return;
                    end

                    rankG = rank(mod(double(G),2));
                    if rankG < 3
                        uialert(f, 'La matrice G n''est pas de rang complet. Les lignes doivent être indépendantes.', 'Matrice invalide');
                        return;
                    end

                    H = app.computeParityCheckFromG(G);
                    codeStruct = app.generateAllCodewords(G);
                    codewords = codeStruct.codewords;
                    messages = codeStruct.messages;
                    weights = sum(codewords, 2);
                    dmin = app.computeMinDistance(codewords);

                    MatrixTableG.Data = G;
                    MatrixTableH.Data = H;
                    CodewordsTable.Data = [messages codewords weights];

                    state.G = G;
                    state.H = H;
                    state.codewords = codewords;
                    state.messages = messages;
                    state.lastCodeword = [];
                    state.lastReceived = [];
                    state.lastCorrected = [];

                    SummaryArea.Value = {
                        'Analyse terminée avec succès.'
                        ['Paramètres du code : C(' num2str(n) ',' num2str(k) ')']
                        ['Nombre total de mots-code : ' num2str(size(codewords,1))]
                        ['Distance minimale de Hamming dmin = ' num2str(dmin)]
                        ['Capacité de correction : t = floor((dmin-1)/2) = ' num2str(floor((dmin-1)/2))]
                        'Le poids de chaque mot-code est affiché dans le tableau.'
                        'La matrice H est calculée de sorte que G * H'' = 0 mod 2.'
                    };

                    StepsArea.Value = {
                        'Étape 1 : G validée. Étape 2 : génération des 8 messages. Étape 3 : calcul des mots-code c = mG mod 2. Étape 4 : calcul de dmin. Étape 5 : calcul de H.'
                    };

                catch ME
                    uialert(f, ME.message, 'Erreur');
                end
            end

            function onSimulateError(~, ~)
                try
                    if isempty(state.G)
                        uialert(f, 'Cliquez d''abord sur "GÉNÉRER / ANALYSER".', 'Données manquantes');
                        return;
                    end

                    m = app.parseBinaryVector(MsgField.Value, 3);
                    c = mod(m * state.G, 2);

                    kerr = round(ErrPosSpinner.Value);
                    r = c;
                    r(kerr) = mod(r(kerr) + 1, 2);

                    state.lastCodeword = c;
                    state.lastReceived = r;

                    SummaryArea.Value = {
                        'Simulation d''erreur terminée.'
                        ['Message choisi m = ' app.vec2str(m)]
                        ['Mot-code émis c = ' app.vec2str(c)]
                        ['Position de l''erreur k = ' num2str(kerr)]
                        ['Mot reçu r = ' app.vec2str(r)]
                    };

                    StepsArea.Value = {
                        ['On calcule d''abord c = mG mod 2 = ' app.vec2str(c) ...
                         ' puis on inverse le bit en position ' num2str(kerr) ...
                         ' pour obtenir r = ' app.vec2str(r)]
                    };

                catch ME
                    uialert(f, ME.message, 'Erreur');
                end
            end

            function onDecodeCorrect(~, ~)
                try
                    if isempty(state.H)
                        uialert(f, 'Cliquez d''abord sur "GÉNÉRER / ANALYSER".', 'Données manquantes');
                        return;
                    end

                    if isempty(state.lastReceived)
                        uialert(f, 'Il faut d''abord simuler une erreur.', 'Mot reçu manquant');
                        return;
                    end

                    r = state.lastReceived;
                    H = state.H;

                    syndrome = mod(r * H', 2);
                    errPos = app.findErrorPositionFromSyndrome(H, syndrome);

                    cHat = r;
                    if errPos > 0
                        cHat(errPos) = mod(cHat(errPos) + 1, 2);
                    end

                    mHat = app.decodeMessageFromCodeword(cHat, state.codewords, state.messages);
                    state.lastCorrected = cHat;

                    if all(syndrome == 0)
                        synText = 'Aucune erreur détectée.';
                    else
                        synText = ['Erreur détectée à la position : ' num2str(errPos)];
                    end

                    SummaryArea.Value = {
                        'Décodage / correction terminé.'
                        ['Mot reçu r = ' app.vec2str(r)]
                        ['Syndrome s = rH'' mod 2 = ' app.vec2str(syndrome)]
                        synText
                        ['Mot corrigé = ' app.vec2str(cHat)]
                        ['Message décodé = ' app.vec2str(mHat)]
                    };

                    StepsArea.Value = {
                        ['1) r = ' app.vec2str(r) ...
                         '   2) s = ' app.vec2str(syndrome) ...
                         '   3) position erreur = ' num2str(errPos) ...
                         '   4) mot corrigé = ' app.vec2str(cHat) ...
                         '   5) message retrouvé = ' app.vec2str(mHat)]
                    };

                catch ME
                    uialert(f, ME.message, 'Erreur');
                end
            end

            function onClear(~, ~)
                GArea.Value = splitlines(string(defaultG));
                MsgField.Value = '1 0 0';
                ErrPosSpinner.Value = 1;

                MatrixTableG.Data = {};
                MatrixTableH.Data = {};
                CodewordsTable.Data = {};

                SummaryArea.Value = {'Les résultats apparaîtront ici...'};
                StepsArea.Value = {'Les étapes détaillées apparaîtront ici...'};

                state.G = [];
                state.H = [];
                state.codewords = [];
                state.messages = [];
                state.lastCodeword = [];
                state.lastReceived = [];
                state.lastCorrected = [];
            end
        end

        function M = parseBinaryMatrix(app, valueLines, expectedRows, expectedCols)
            %#ok<INUSD>
            if ischar(valueLines) || isstring(valueLines)
                valueLines = cellstr(splitlines(string(valueLines)));
            end

            valueLines = valueLines(~cellfun(@isempty, strtrim(valueLines)));

            if numel(valueLines) ~= expectedRows
                error('La matrice doit contenir exactement %d lignes.', expectedRows);
            end

            M = zeros(expectedRows, expectedCols);

            for i = 1:expectedRows
                rowStr = strtrim(valueLines{i});
                nums = sscanf(rowStr, '%f')';

                if numel(nums) ~= expectedCols
                    error('La ligne %d doit contenir exactement %d valeurs.', i, expectedCols);
                end

                if any(~ismember(nums, [0 1]))
                    error('La matrice doit être binaire : uniquement 0 et 1.');
                end

                M(i,:) = nums;
            end

            M = mod(M, 2);
        end

        function v = parseBinaryVector(app, txt, n)
            %#ok<INUSD>
            vals = sscanf(char(txt), '%f')';

            if numel(vals) ~= n
                error('Le vecteur doit contenir exactement %d valeurs binaires.', n);
            end

            if any(~ismember(vals, [0 1]))
                error('Le vecteur doit être binaire : uniquement 0 et 1.');
            end

            v = mod(vals, 2);
        end

        function out = vec2str(app, v)
            %#ok<INUSD>
            out = ['[' sprintf('%d ', v) ']'];
            out = strrep(out, ' ]', ']');
        end

        function H = computeParityCheckFromG(app, G)
            %#ok<INUSD>
            [Gs, pivots] = app.toSystematicFormBinary(G);
            k = size(Gs,1);
            n = size(Gs,2);
            P = Gs(:, k+1:n);
            Hsys = [P' eye(n-k)];

            perm = [pivots setdiff(1:n, pivots, 'stable')];
            invPerm = zeros(1,n);

            for i = 1:n
                invPerm(perm(i)) = i;
            end

            H = Hsys(:, invPerm);
            H = mod(H,2);
        end

        function [Gs, pivots] = toSystematicFormBinary(app, G)
            %#ok<INUSD>
            Gs = mod(G,2);
            [k,n] = size(Gs);
            pivots = zeros(1,k);
            row = 1;

            for col = 1:n
                if row > k
                    break;
                end

                pivotRow = 0;
                for r = row:k
                    if Gs(r,col) == 1
                        pivotRow = r;
                        break;
                    end
                end

                if pivotRow == 0
                    continue;
                end

                if pivotRow ~= row
                    temp = Gs(row,:);
                    Gs(row,:) = Gs(pivotRow,:);
                    Gs(pivotRow,:) = temp;
                end

                if col ~= row
                    temp = Gs(:,row);
                    Gs(:,row) = Gs(:,col);
                    Gs(:,col) = temp;
                end

                pivots(row) = col;

                for r = 1:k
                    if r ~= row && Gs(r,row) == 1
                        Gs(r,:) = mod(Gs(r,:) + Gs(row,:), 2);
                    end
                end

                row = row + 1;
            end

            if any(pivots == 0)
                error('Impossible de transformer G en forme systématique. Vérifiez que G est de rang complet.');
            end
        end

        function S = generateAllCodewords(app, G)
            %#ok<INUSD>
            k = size(G,1);
            msgs = dec2bin(0:(2^k - 1)) - '0';
            codewords = mod(msgs * G, 2);
            S = struct('messages', msgs, 'codewords', codewords);
        end

        function dmin = computeMinDistance(app, codewords)
            %#ok<INUSD>
            weights = sum(codewords, 2);
            nz = weights(weights > 0);

            if isempty(nz)
                dmin = 0;
            else
                dmin = min(nz);
            end
        end

        function pos = findErrorPositionFromSyndrome(app, H, syndrome)
            %#ok<INUSD>
            pos = 0;

            if all(syndrome == 0)
                return;
            end

            for j = 1:size(H,2)
                if isequal(H(:,j)', syndrome)
                    pos = j;
                    return;
                end
            end
        end

        function m = decodeMessageFromCodeword(app, cHat, codewords, messages)
            %#ok<INUSD>
            idx = find(ismember(codewords, cHat, 'rows'), 1);

            if isempty(idx)
                error('Le mot corrigé n''a pas été trouvé dans le dictionnaire. Il y a peut-être plus d''une erreur.');
            end

            m = messages(idx,:);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MISE EN PAGE RESPONSIVE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function onFigureResized(app, ~, ~)
            app.layoutComponents();
        end

        function layoutComponents(app)
            figPos = app.UIFigure.Position;
            W = figPos(3);
            H = figPos(4);

            outerMargin = 10;
            gap = 10;
            titleH = 42;
            footerH = 22;

            app.TitleLabel.Position = [max(20, W*0.15) H-titleH-4 max(500, W*0.68) titleH];
            app.MainPanel.Position = [outerMargin outerMargin W-2*outerMargin H-titleH-2*outerMargin-6];

            mp = app.MainPanel.Position;
            mW = mp(3);
            mH = mp(4);

            menuW = max(230, round(mW * 0.19));
            rightW = mW - menuW - 3*gap;

            app.MenuPanel.Position = [gap gap menuW mH-2*gap];

            displayH = round(mH * 0.40);
            middleH  = round(mH * 0.25);
            paramsH  = mH - displayH - middleH - 4*gap - footerH;

            if paramsH < 190
                paramsH = 190;
                middleH = mH - displayH - paramsH - 4*gap - footerH;
            end

            if middleH < 150
                middleH = 150;
                displayH = mH - middleH - paramsH - 4*gap - footerH;
            end

            rightX = menuW + 2*gap;

            app.DisplayPanel.Position = [rightX mH-gap-displayH rightW displayH];
            app.ParamsPanel.Position  = [rightX footerH+gap rightW paramsH];

            midY = footerH + paramsH + 2*gap;
            app.FooterLabel.Position = [rightX + max(10, rightW-650) 2 640 18];

            dp = app.DisplayPanel.Position;
            dpW = dp(3);
            dpH = dp(4);

            axMarginX = 28;
            axMarginTop = 38;
            axMarginBottom = 22;
            axGap = 40;

            axW = floor((dpW - 2*axMarginX - axGap) / 2);
            axH = dpH - axMarginTop - axMarginBottom - 18;

            app.UIAxesOriginal.Position = [axMarginX axMarginBottom axW axH];
            app.UIAxesDecoded.Position  = [axMarginX + axW + axGap axMarginBottom axW axH];

            colGap = 14;
            colW = floor((rightW - 2*colGap) / 3);

            labelY = midY + middleH - 22;
            boxY   = midY;
            boxH   = middleH - 28;

            x1 = rightX;
            x2 = x1 + colW + colGap;
            x3 = x2 + colW + colGap;

            app.SourceInfoLabel.Position = [x1+10 labelY 140 22];
            app.ResultLabel.Position     = [x2+10 labelY 180 22];
            app.CompareLabel.Position    = [x3+10 labelY 210 22];

            app.SourceInfoTextArea.Position = [x1 boxY colW boxH];
            app.ResultTextArea.Position     = [x2 boxY colW boxH];
            app.ComparisonTable.Position    = [x3 boxY colW boxH];

            pp = app.ParamsPanel.Position;
            pW = pp(3);
            pH = pp(4);

            row1YLabel = pH - 70;
            row1YField = pH - 100;
            row2YLabel = 55;
            row2YField = 25;

            leftPad = 24;
            fieldW = floor((pW - 6*leftPad) / 5);
            fieldGap = leftPad;

            xs = zeros(1,5);
            xs(1) = leftPad;
            for i = 2:5
                xs(i) = xs(i-1) + fieldW + fieldGap;
            end

            app.OriginalSizeLabel.Position  = [xs(1) row1YLabel 140 22];
            app.OriginalSizeField.Position  = [xs(1) row1YField fieldW 24];

            app.HuffmanSizeLabel.Position   = [xs(2) row1YLabel 120 22];
            app.HuffmanSizeField.Position   = [xs(2) row1YField fieldW 24];

            app.ShannonSizeLabel.Position   = [xs(3) row1YLabel 120 22];
            app.ShannonSizeField.Position   = [xs(3) row1YField fieldW 24];

            app.HuffmanRatioLabel.Position  = [xs(4) row1YLabel 120 22];
            app.HuffmanRatioField.Position  = [xs(4) row1YField fieldW 24];

            app.ShannonRatioLabel.Position  = [xs(5) row1YLabel 120 22];
            app.ShannonRatioField.Position  = [xs(5) row1YField fieldW 24];

            app.HuffmanEffLabel.Position    = [xs(1) row2YLabel 160 22];
            app.HuffmanEffField.Position    = [xs(1) row2YField fieldW 24];

            app.ShannonEffLabel.Position    = [xs(2) row2YLabel 165 22];
            app.ShannonEffField.Position    = [xs(2) row2YField fieldW 24];

            app.HuffmanTimeLabel.Position   = [xs(3) row2YLabel 130 22];
            app.HuffmanTimeField.Position   = [xs(3) row2YField fieldW 24];

            app.ShannonTimeLabel.Position   = [xs(4) row2YLabel 130 22];
            app.ShannonTimeField.Position   = [xs(4) row2YField fieldW 24];

            menuX = 18;
            menuTop = app.MenuPanel.Position(4) - 60;
            btnW = app.MenuPanel.Position(3) - 2*menuX - 25;
            btnH = 36;
            dropW = min(btnW, 180);

            app.AlgorithmDropDownLabel.Position = [menuX menuTop-22 100 22];
            app.AlgorithmDropDown.Position      = [menuX menuTop-52 dropW 28];

            app.ExtensionSpinnerLabel.Position  = [menuX menuTop-92 130 22];
            app.ExtensionSpinner.Position       = [min(menuX+150, app.MenuPanel.Position(3)-70) menuTop-92 50 24];

            y0 = menuTop - 145;
            step = 48;

            app.OPENButton.Position         = [menuX y0 btnW btnH];
            app.COMPRESSButton.Position     = [menuX y0-step btnW btnH];
            app.DECOMPRESSButton.Position   = [menuX y0-2*step btnW btnH];
            app.COMPAREButton.Position      = [menuX y0-3*step btnW btnH];
            app.SHOWHUFFTREEButton.Position = [menuX y0-4*step btnW btnH];
            app.SHOWSFTREEButton.Position   = [menuX y0-5*step btnW btnH];
            app.LINEARCODEButton.Position   = [menuX y0-6*step btnW btnH];
            app.RESETButton.Position        = [menuX y0-7*step btnW btnH];
            app.EXITButton.Position         = [menuX y0-8*step btnW btnH];
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CRÉATION DE L'INTERFACE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function createComponents(app)

            bgMain   = [0.85 0.93 0.97];
            panelBg  = [0.97 0.95 0.91];
            menuBg   = [0.94 0.90 0.84];
            accent   = [0.14 0.52 0.71];
            goldBtn  = [0.92 0.69 0.14];
            textDark = [0.12 0.16 0.22];

            screenSize = get(groot, 'ScreenSize');
            figW = max(1100, min(1500, screenSize(3) - 80));
            figH = max(760,  min(900,  screenSize(4) - 100));
            figX = max(10, floor((screenSize(3) - figW)/2));
            figY = max(10, floor((screenSize(4) - figH)/2));

            app.UIFigure = uifigure('Visible', 'off', 'AutoResizeChildren', 'off');
            app.UIFigure.Name = 'Application - Huffman / Shannon-Fano / Code linéaire';
            app.UIFigure.Position = [figX figY figW figH];
            app.UIFigure.Color = [0.96 0.97 0.98];
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @onFigureResized, true);

            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.Text = 'PROJET DE CODAGE DE SOURCE - HUFFMAN / SHANNON-FANO / CODE LINÉAIRE';
            app.TitleLabel.FontName = 'Times New Roman';
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontAngle = 'italic';
            app.TitleLabel.FontSize = 24;
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontColor = [0.78 0.30 0.10];

            app.MainPanel = uipanel(app.UIFigure, 'AutoResizeChildren', 'off');
            app.MainPanel.BackgroundColor = bgMain;
            app.MainPanel.BorderType = 'line';
            app.MainPanel.HighlightColor = accent;

            app.MenuPanel = uipanel(app.MainPanel, 'AutoResizeChildren', 'off');
            app.MenuPanel.Title = 'MENU';
            app.MenuPanel.FontWeight = 'bold';
            app.MenuPanel.FontAngle = 'italic';
            app.MenuPanel.FontSize = 16;
            app.MenuPanel.FontName = 'Arial Black';
            app.MenuPanel.BackgroundColor = menuBg;

            app.AlgorithmDropDownLabel = uilabel(app.MenuPanel);
            app.AlgorithmDropDownLabel.Text = 'Algorithme';
            app.AlgorithmDropDownLabel.FontWeight = 'bold';
            app.AlgorithmDropDownLabel.FontColor = textDark;

            app.AlgorithmDropDown = uidropdown(app.MenuPanel);
            app.AlgorithmDropDown.Items = {'Huffman', 'Shannon-Fano'};
            app.AlgorithmDropDown.Value = 'Huffman';

            app.ExtensionSpinnerLabel = uilabel(app.MenuPanel);
            app.ExtensionSpinnerLabel.Text = 'Ordre d''extension N';
            app.ExtensionSpinnerLabel.FontWeight = 'bold';
            app.ExtensionSpinnerLabel.FontColor = textDark;

            app.ExtensionSpinner = uispinner(app.MenuPanel);
            app.ExtensionSpinner.Limits = [1 10];
            app.ExtensionSpinner.Step = 1;
            app.ExtensionSpinner.Value = 1;

            buttonStyle = {'FontName','Arial Black','FontSize',12,'BackgroundColor',goldBtn};

            app.OPENButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.OPENButton.Text = 'OUVRIR';
            app.OPENButton.ButtonPushedFcn = createCallbackFcn(app, @OPENButtonPushed, true);

            app.COMPRESSButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.COMPRESSButton.Text = 'COMPRESSER';
            app.COMPRESSButton.ButtonPushedFcn = createCallbackFcn(app, @COMPRESSButtonPushed, true);

            app.DECOMPRESSButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.DECOMPRESSButton.Text = 'DÉCOMPRESSER';
            app.DECOMPRESSButton.ButtonPushedFcn = createCallbackFcn(app, @DECOMPRESSButtonPushed, true);

            app.COMPAREButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.COMPAREButton.Text = 'COMPARER';
            app.COMPAREButton.ButtonPushedFcn = createCallbackFcn(app, @COMPAREButtonPushed, true);

            app.SHOWHUFFTREEButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.SHOWHUFFTREEButton.Text = 'ARBRE HUFFMAN';
            app.SHOWHUFFTREEButton.ButtonPushedFcn = createCallbackFcn(app, @SHOWHUFFTREEButtonPushed, true);

            app.SHOWSFTREEButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.SHOWSFTREEButton.Text = 'ARBRE S-F';
            app.SHOWSFTREEButton.ButtonPushedFcn = createCallbackFcn(app, @SHOWSFTREEButtonPushed, true);

            app.LINEARCODEButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.LINEARCODEButton.Text = 'CODE C(7,3)';
            app.LINEARCODEButton.ButtonPushedFcn = createCallbackFcn(app, @LINEARCODEButtonPushed, true);

            app.RESETButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.RESETButton.Text = 'RÉINITIALISER';
            app.RESETButton.ButtonPushedFcn = createCallbackFcn(app, @RESETButtonPushed, true);

            app.EXITButton = uibutton(app.MenuPanel, 'push', buttonStyle{:});
            app.EXITButton.Text = 'QUITTER';
            app.EXITButton.ButtonPushedFcn = createCallbackFcn(app, @EXITButtonPushed, true);

            app.DisplayPanel = uipanel(app.MainPanel, 'AutoResizeChildren', 'off');
            app.DisplayPanel.Title = 'AFFICHAGE SOURCE / DÉCODAGE';
            app.DisplayPanel.FontWeight = 'bold';
            app.DisplayPanel.FontAngle = 'italic';
            app.DisplayPanel.FontSize = 15;
            app.DisplayPanel.FontName = 'Arial Black';
            app.DisplayPanel.BackgroundColor = panelBg;

            app.UIAxesOriginal = uiaxes(app.DisplayPanel);
            title(app.UIAxesOriginal, 'Original')
            app.UIAxesOriginal.XTick = [];
            app.UIAxesOriginal.YTick = [];
            app.UIAxesOriginal.Box = 'on';

            app.UIAxesDecoded = uiaxes(app.DisplayPanel);
            title(app.UIAxesDecoded, 'Décodé')
            app.UIAxesDecoded.XTick = [];
            app.UIAxesDecoded.YTick = [];
            app.UIAxesDecoded.Box = 'on';

            labelStyle = {'FontName','Arial Black','FontWeight','bold','FontAngle','italic','FontColor',textDark};

            app.SourceInfoLabel = uilabel(app.MainPanel, labelStyle{:});
            app.SourceInfoLabel.Text = 'INFOS SOURCE';

            app.ResultLabel = uilabel(app.MainPanel, labelStyle{:});
            app.ResultLabel.Text = 'RÉSULTATS / THÉORIE';

            app.CompareLabel = uilabel(app.MainPanel, labelStyle{:});
            app.CompareLabel.Text = 'TABLEAU DE COMPARAISON';

            app.SourceInfoTextArea = uitextarea(app.MainPanel);
            app.SourceInfoTextArea.BackgroundColor = [1 1 1];

            app.ResultTextArea = uitextarea(app.MainPanel);
            app.ResultTextArea.BackgroundColor = [1 1 1];

            app.ComparisonTable = uitable(app.MainPanel);
            app.ComparisonTable.ColumnName = {'Méthode','Taille','Taux','H(N)','H/Sym','L/Sym','Eff(%)','Temps(s)'};
            app.ComparisonTable.RowName = {};
            app.ComparisonTable.ColumnEditable = false(1,8);
            app.ComparisonTable.FontSize = 12;

            app.ParamsPanel = uipanel(app.MainPanel, 'AutoResizeChildren', 'off');
            app.ParamsPanel.Title = 'PARAMÈTRES';
            app.ParamsPanel.FontWeight = 'bold';
            app.ParamsPanel.FontAngle = 'italic';
            app.ParamsPanel.FontSize = 15;
            app.ParamsPanel.FontName = 'Arial Black';
            app.ParamsPanel.BackgroundColor = panelBg;

            app.OriginalSizeLabel = uilabel(app.ParamsPanel);   app.OriginalSizeLabel.Text = 'Taille originale (bits)';
            app.HuffmanSizeLabel  = uilabel(app.ParamsPanel);   app.HuffmanSizeLabel.Text  = 'Taille Huffman';
            app.ShannonSizeLabel  = uilabel(app.ParamsPanel);   app.ShannonSizeLabel.Text  = 'Taille Shannon';
            app.HuffmanRatioLabel = uilabel(app.ParamsPanel);   app.HuffmanRatioLabel.Text = 'Taux Huffman';
            app.ShannonRatioLabel = uilabel(app.ParamsPanel);   app.ShannonRatioLabel.Text = 'Taux Shannon';
            app.HuffmanEffLabel   = uilabel(app.ParamsPanel);   app.HuffmanEffLabel.Text   = 'Efficacité Huffman (%)';
            app.ShannonEffLabel   = uilabel(app.ParamsPanel);   app.ShannonEffLabel.Text   = 'Efficacité Shannon (%)';
            app.HuffmanTimeLabel  = uilabel(app.ParamsPanel);   app.HuffmanTimeLabel.Text  = 'Temps Huffman (s)';
            app.ShannonTimeLabel  = uilabel(app.ParamsPanel);   app.ShannonTimeLabel.Text  = 'Temps Shannon (s)';

            app.OriginalSizeField = uieditfield(app.ParamsPanel, 'text');
            app.HuffmanSizeField  = uieditfield(app.ParamsPanel, 'text');
            app.ShannonSizeField  = uieditfield(app.ParamsPanel, 'text');
            app.HuffmanRatioField = uieditfield(app.ParamsPanel, 'text');
            app.ShannonRatioField = uieditfield(app.ParamsPanel, 'text');
            app.HuffmanEffField   = uieditfield(app.ParamsPanel, 'text');
            app.ShannonEffField   = uieditfield(app.ParamsPanel, 'text');
            app.HuffmanTimeField  = uieditfield(app.ParamsPanel, 'text');
            app.ShannonTimeField  = uieditfield(app.ParamsPanel, 'text');

            app.FooterLabel = uilabel(app.MainPanel);
            app.FooterLabel.Text = 'Présentateurs : Omar Hassan Abdoul-fatah  & Yameogo Ariel Barthelemy Wendtoin';
            app.FooterLabel.FontName = 'Arial Black';
            app.FooterLabel.FontColor = textDark;

            app.layoutComponents();
            app.UIFigure.Visible = 'on';
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CRÉATION / SUPPRESSION APP
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)

        function app = Application
            createComponents(app)
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end

function s = double2str(x)
s = sprintf('%d_', x);
end
