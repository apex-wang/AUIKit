package io.agora.auikit.ui.action.impI

import android.content.res.TypedArray
import android.graphics.Typeface
import android.os.Bundle
import android.util.SparseArray
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.util.forEach
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import io.agora.auikit.ui.R
import io.agora.auikit.ui.action.AUIActionUserInfo
import io.agora.auikit.ui.action.AUIActionUserInfoList
import io.agora.auikit.ui.action.IAUIListViewBinderRefresh
import io.agora.auikit.ui.action.fragment.VoiceRoomApplyListFragment
import io.agora.auikit.ui.action.listener.AUIApplyDialogEventListener
import io.agora.auikit.ui.basic.AUISheetFragmentDialog
import io.agora.auikit.ui.databinding.AuiApplyLayoutBinding
import io.agora.auikit.utils.ResourcesTools

class AUIApplyDialog : AUISheetFragmentDialog<AuiApplyLayoutBinding>(),IAUIListViewBinderRefresh{

    companion object {
        const val KEY_ROOM_APPLY_BEAN = "room_apply_bean"
        const val KEY_CURRENT_ITEM = "current_Item"
    }

    private val roomBean: AUIActionUserInfoList by lazy {
        arguments?.getSerializable(KEY_ROOM_APPLY_BEAN) as AUIActionUserInfoList
    }

    private val currentItem: Int by lazy {
        arguments?.getInt(KEY_CURRENT_ITEM, 0) ?: 0
    }

    private var adapter: RoomApplyFragmentAdapter?=null
    private var listener: AUIApplyDialogEventListener?=null
    private var appearanceId:Int = 0
    private var mTabSelectedColor:Int = 0
    private var mTabUnSelectedColor:Int = 0

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): AuiApplyLayoutBinding {
        return AuiApplyLayoutBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // 获取自定义样式的ID
        activity?.let {
            val themeTa: TypedArray = it.theme.obtainStyledAttributes(R.styleable.AUIAction)
            appearanceId = themeTa.getResourceId(R.styleable.AUIAction_aui_action_appearance, 0)
            themeTa.recycle()
        }

        initFragmentAdapter()
    }

    override fun setApplyDialogListener(listener:AUIApplyDialogEventListener){
        this.listener = listener
    }

    private fun initFragmentAdapter() {
        activity?.let { fragmentActivity->
            val typedArray = fragmentActivity.obtainStyledAttributes(appearanceId, R.styleable.AUIAction)
            mTabSelectedColor = typedArray.getResourceId(
                R.styleable.AUIAction_aui_tabLayout_selected_textColor,
                R.color.aui_color_040925
            )
            mTabUnSelectedColor = typedArray.getResourceId(
                R.styleable.AUIAction_aui_tabLayout_unselected_textColor,
                R.color.aui_color_6c7192
            )
            typedArray.recycle()

            adapter = RoomApplyFragmentAdapter(fragmentActivity,roomBean,listener)
            binding?.apply {
                setOnApplyWindowInsets(root)
                vpApplyLayout.adapter = adapter
                val tabMediator = TabLayoutMediator(tabApplyLayout, vpApplyLayout) { tab, position ->
                    val customView =
                        LayoutInflater.from(root.context).inflate(R.layout.aui_action_tab_item_layout, tab.view, false)
                    val tabText = customView.findViewById<TextView>(R.id.mtTabText)
                    tab.customView = customView
                    if (position == RoomApplyFragmentAdapter.PAGE_INDEX0) {
                        tabText.text = getString(R.string.aui_room_apply_list)
                        onTabLayoutSelected(tab)
                    } else {
                        onTabLayoutUnselected(tab)
                    }

                }
                tabMediator.attach()
                tabApplyLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
                    override fun onTabSelected(tab: TabLayout.Tab?) {
                        onTabLayoutSelected(tab)
                    }

                    override fun onTabUnselected(tab: TabLayout.Tab?) {
                        onTabLayoutUnselected(tab)
                    }

                    override fun onTabReselected(tab: TabLayout.Tab?) {
                    }
                })
                vpApplyLayout.setCurrentItem(currentItem, false)
            }
        }
    }

    override fun refreshApplyData(userList: MutableList<AUIActionUserInfo?>){
        adapter?.refreshData(userList)
    }

    private fun onTabLayoutSelected(tab: TabLayout.Tab?) {
        tab?.customView?.let {
            val tabText = it.findViewById<TextView>(R.id.mtTabText)
            tabText.setTextColor(ResourcesTools.getColor(resources, mTabSelectedColor))
            tabText.typeface = Typeface.defaultFromStyle(Typeface.BOLD)
            val tabTip = it.findViewById<View>(R.id.vTabTip)
            tabTip.visibility = View.VISIBLE
        }
    }

    private fun onTabLayoutUnselected(tab: TabLayout.Tab?) {
        tab?.customView?.let {
            val tabText = it.findViewById<TextView>(R.id.mtTabText)
            tabText.setTextColor(ResourcesTools.getColor(resources, mTabUnSelectedColor))
            tabText.typeface = Typeface.defaultFromStyle(Typeface.NORMAL)
            val tabTip = it.findViewById<View>(R.id.vTabTip)
            tabTip.visibility = View.GONE
        }
    }

    class RoomApplyFragmentAdapter constructor(
        fragmentActivity: FragmentActivity,
        roomBean: AUIActionUserInfoList,
        event:AUIApplyDialogEventListener?
    ) : FragmentStateAdapter(fragmentActivity), VoiceRoomApplyListFragment.ApplyEventListener {

        companion object {
            const val PAGE_INDEX0 = 0
            const val PAGE_INDEX1 = 1
        }

        private val fragments: SparseArray<Fragment> = SparseArray()
        private var listener:AUIApplyDialogEventListener?=null

        init {
            this.listener = event
            with(fragments) {
                put(PAGE_INDEX0, VoiceRoomApplyListFragment.getInstance(fragmentActivity,roomBean))
            }
        }

        override fun createFragment(position: Int): Fragment {
            val fragment = fragments[position]
            if (PAGE_INDEX0 == position){
                (fragment as VoiceRoomApplyListFragment).setApplyEventListener(this)
            }
            return fragment
        }

        override fun getItemCount(): Int {
            return fragments.size()
        }

        fun refreshData(userList:MutableList<AUIActionUserInfo?>){
            fragments.forEach { key, value ->
                if (key == PAGE_INDEX0){
                    val fragment = value as VoiceRoomApplyListFragment
                    fragment.refreshData(userList)
                }
            }
        }

        override fun onApplyItemClick(view: View, applyIndex: Int?, user: AUIActionUserInfo?, position: Int) {
            this.listener?.onApplyItemClick(view, applyIndex, user,position)
        }
    }

}