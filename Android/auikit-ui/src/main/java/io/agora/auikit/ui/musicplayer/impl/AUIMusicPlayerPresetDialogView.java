package io.agora.auikit.ui.musicplayer.impl;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

import io.agora.auikit.ui.R;
import io.agora.auikit.ui.basic.AUIRecyclerView;
import io.agora.auikit.ui.musicplayer.ControllerEffectInfo;

public class AUIMusicPlayerPresetDialogView extends FrameLayout {

    private RecyclerView.Adapter<RecyclerView.ViewHolder> mMusicPlayerPresetAdapter;

    private int currentId;

    public AUIMusicPlayerPresetDialogView(@NonNull Context context) {
        this(context, null);
    }

    public AUIMusicPlayerPresetDialogView(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public AUIMusicPlayerPresetDialogView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        this(context, attrs, defStyleAttr, 0);
    }

    public AUIMusicPlayerPresetDialogView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView(context);
    }

    private void initView(@NonNull Context context) {
        View.inflate(context, R.layout.aui_musicplayer_preset_dialog_view, this);
        AUIRecyclerView rvAudioPreset = findViewById(R.id.rv_audio_preset);
        List<ControllerEffectInfo> presetList = buildPresetData();
        mMusicPlayerPresetAdapter = new RecyclerView.Adapter<RecyclerView.ViewHolder>() {
            @NonNull
            @Override
            public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
                return new RecyclerView.ViewHolder(new AUIMusicPlayerEffectItemView(parent.getContext())) {
                };
            }

            @Override
            public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
                AUIMusicPlayerEffectItemView itemView = (AUIMusicPlayerEffectItemView) holder.itemView;
                final ControllerEffectInfo effectVoiceInfo = presetList.get(position);
                if (effectVoiceInfo == null) {
                    return;
                }
                itemView.setPresetInnerIcon(effectVoiceInfo.getIcon());
                itemView.setItemSelected(currentId == effectVoiceInfo.getIndex());
                itemView.setPresetName(itemView.getContext().getString(effectVoiceInfo.getTitle()));
                itemView.setOnClickListener(v -> {
                    currentId = effectVoiceInfo.getIndex();
                    mMusicPlayerPresetAdapter.notifyDataSetChanged();
                });
            }

            @Override
            public int getItemCount() {
                return presetList.size();
            }
        };
        rvAudioPreset.setAdapter(mMusicPlayerPresetAdapter);
    }

    private List<ControllerEffectInfo> buildPresetData() {
        List<ControllerEffectInfo> list = new ArrayList<>();
        list.add(new ControllerEffectInfo(0, 0, R.drawable.aui_musicplayer_preset_none, R.string.aui_musicplayer_preset_original));
        list.add(new ControllerEffectInfo(1, 1, R.drawable.aui_musicplayer_preset_child, R.string.aui_musicplayer_preset_child));
        list.add(new ControllerEffectInfo(2, 2, R.drawable.aui_musicplayer_preset_lolita, R.string.aui_musicplayer_preset_lolita));
        list.add(new ControllerEffectInfo(3, 3, R.drawable.aui_musicplayer_preset_uncle, R.string.aui_musicplayer_preset_uncle));
        list.add(new ControllerEffectInfo(4, 4, R.drawable.aui_musicplayer_preset_airy, R.string.aui_musicplayer_preset_airy));
        return list;
    }
}
